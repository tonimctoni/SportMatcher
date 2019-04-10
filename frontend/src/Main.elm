import Browser
import Browser.Navigation as Nav
import Url
import Url.Parser as Parser exposing (Parser, (</>))
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import String
import Array


main =
  Browser.application { init=init, view=view, update=update, subscriptions=\_-> Sub.none, onUrlRequest=UrlRequest, onUrlChange=UrlChange}


-- MODEL

type alias Model =
  { key: Nav.Key
  , url: Url.Url
  , route: Route
  , error: String
  , poll_title: String
  , poll_number: Int
  , poll_type_is_free: Bool
  , poll_questions_field: String
  , poll_questions: Maybe PollQuestions
  , poll_answers: Maybe PollAnswers
  , user_name: String
  , fixed_answers: Array.Array Int
  , free_answers: String
  , submitted_answers: Bool
  }

make_default_model: Nav.Key -> Url.Url -> Model
make_default_model key url = Model key url RouteError "" "" 0 False "" Nothing Nothing "" Array.empty "" False

init: () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
  (make_default_model key url , Nav.replaceUrl key <| Url.toString url)


-- REST (ish)

type alias StartPollOutput =
  { poll_id: String
  , error: String
  }

send_put_poll: Model -> Cmd Msg
send_put_poll model =
  let
    questions=if model.poll_type_is_free
      then ""
      else if String.length model.poll_questions_field==0
        then "a"
        else model.poll_questions_field
    body =
      [ ("number", Encode.int model.poll_number)
      , ("title", Encode.string model.poll_title)
      , ("questions", Encode.string questions)
      ]
      |> Encode.object
      |> Http.jsonBody

    decoder = Decode.map2 StartPollOutput
      (Decode.field "poll_id" Decode.string)
      (Decode.field "error" Decode.string)
  in
    Http.request {method="PUT", headers=[], url="/api/poll", body=body, expect=Http.expectJson PutPollResult decoder, timeout=Nothing, tracker=Nothing}


type alias PollQuestions =
  { title: String
  , questions: Array.Array String
  , polls_filled: Int
  , polls_number: Int
  }

type alias PollAnswers =
  { title: String
  , user_names: Array.Array String
  , all_yay: Array.Array String
  , all_open: Array.Array String
  }

type alias GetPollOutput =
  { questions: Maybe PollQuestions
  , answers: Maybe PollAnswers
  , error: String
  }

send_get_poll: String -> Cmd Msg
send_get_poll poll_id =
  let
    questions_decoder = Decode.map4 PollQuestions
      (Decode.field "title" Decode.string)
      (Decode.field "questions" (Decode.array Decode.string))
      (Decode.field "polls_filled" Decode.int)
      (Decode.field "polls_number" Decode.int)

    answers_decoder = Decode.map4 PollAnswers
      (Decode.field "title" Decode.string)
      (Decode.field "user_names" (Decode.array Decode.string))
      (Decode.field "all_yay" (Decode.array Decode.string))
      (Decode.field "all_open" (Decode.array Decode.string))

    poll_output_decoder = Decode.map3 GetPollOutput
      (Decode.field "questions" (Decode.nullable questions_decoder))
      (Decode.field "answers" (Decode.nullable answers_decoder))
      (Decode.field "error" Decode.string)
  in
    Http.get {url="/api/poll/"++poll_id, expect=Http.expectJson GetPollResult poll_output_decoder}


send_post_poll: String -> Model -> Cmd Msg
send_post_poll poll_id model=
  let
    user_name_encode = Encode.string model.user_name
    fixed_answers_encode=if Array.length model.fixed_answers==0 then Encode.null else Encode.array Encode.int model.fixed_answers
    free_answers_encode =if String.length model.free_answers==0 then Encode.null else Encode.string model.free_answers

    body =
      [ ("user_name", user_name_encode)
      , ("fixed_answers", fixed_answers_encode)
      , ("free_answers", free_answers_encode)
      ]
      |> Encode.object
      |> Http.jsonBody

    return_string_decoder = Decode.string
  in
    Http.post {url="/api/poll/"++poll_id, body=body, expect=Http.expectJson PostPollResult return_string_decoder}

-- UPDATE

type Msg
  = UrlRequest Browser.UrlRequest
  | UrlChange Url.Url
-------- START POLL
  | UpdateTitle String
  | UpdateNumber String
  | ClickedFree Bool
  | UpdateQuestions String
  | ClickedSubmitPoll
  | PutPollResult (Result Http.Error StartPollOutput)
-------- FILL POLL
  | GetPollResult (Result Http.Error GetPollOutput)
  | UpdateUserName String
  | SetFixedAnswer Int Int
  | UpdateFreeAnswers String
  | ClickedSubmitAnswers String
  | PostPollResult (Result Http.Error String)

saturate_range: Int -> Int -> Int -> Int
saturate_range min max num=
  if num<min
  then min
  else if num > max
  then max
  else num

http_err_to_string: Http.Error -> String
http_err_to_string err =
  case err of
    Http.BadUrl s -> "BadUrl("++s++")"
    Http.Timeout -> "Timeout"
    Http.NetworkError -> "NetworkError"
    Http.BadStatus _ -> "BadStatus"
    Http.BadBody s -> "BadPayload("++s++")"

update: Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
-------- START POLL
    UpdateTitle new_title ->
      if String.length new_title<=32 then ({model | poll_title=new_title}, Cmd.none)
      else (model, Cmd.none)
    UpdateNumber new_number ->
      case String.toInt new_number of
        Just new_number_shadowing -> ({model | poll_number=(saturate_range 0 20 new_number_shadowing)}, Cmd.none)
        Nothing -> ({model | poll_number=0}, Cmd.none)
    UpdateQuestions questions ->
      ({model | poll_questions_field=questions}, Cmd.none)
    ClickedFree free ->
      ({model | poll_type_is_free=free}, Cmd.none)
    ClickedSubmitPoll ->
      if String.length model.poll_title<3 then ({model | error="Title must be at least 3 characters long."}, Cmd.none)
      else if model.poll_number<2 || model.poll_number>20 then ({model | error="#Responders must be between 2 and 20."}, Cmd.none)
      else if model.poll_type_is_free==False && model.poll_questions_field=="" then ({model | error="Must specify questions for a fixed answer poll."}, Cmd.none)
      else (model, send_put_poll model)
    PutPollResult (Err err) ->
      ({model | error=http_err_to_string err}, Cmd.none)
    PutPollResult (Ok start_poll_output) ->
      if start_poll_output.error/="" then ({model | error=start_poll_output.error}, Cmd.none)
      else (model, Nav.pushUrl model.key ("/elm_show_poll_link/"++start_poll_output.poll_id))

-------- Fill POLL
    GetPollResult (Err err) ->
      ({model | error=http_err_to_string err}, Cmd.none)
    GetPollResult (Ok poll) ->
      let
        num_fixed_answers = Maybe.withDefault 0 (Maybe.map (\q->Array.length q.questions) poll.questions)
        fixed_answers = Array.repeat num_fixed_answers 3
        error = if poll.error/="" then poll.error
                else if (poll.questions==Nothing && poll.answers==Nothing) || (poll.questions/=Nothing && poll.answers/=Nothing) then "Server did not send either questions or answers (it sent both or neither)."
                else ""
      in
        if error/="" then ({model | error=error}, Cmd.none)
        else ({model | poll_questions=poll.questions, poll_answers=poll.answers, fixed_answers=fixed_answers, free_answers=""}, Cmd.none)
    UpdateUserName user_name ->
      ({model | user_name=user_name}, Cmd.none)
    SetFixedAnswer index state ->
      ({model | fixed_answers=Array.set index state model.fixed_answers}, Cmd.none)
    UpdateFreeAnswers free_answers ->
      ({model | free_answers=free_answers}, Cmd.none)
    ClickedSubmitAnswers poll_id ->
      if model.user_name=="" then ({model | error="Must enter a user name."}, Cmd.none)
      else
        if Array.length model.fixed_answers/=0 then
          if Array.foldr (\v b -> b || v==3) False model.fixed_answers then ({model | error="Must give an answer to all items."}, Cmd.none)
          else (model, send_post_poll poll_id model)
        else
          if String.length model.free_answers==0 then ({model | error="Entry field must not be empty."}, Cmd.none)
          else (model, send_post_poll poll_id model)
    PostPollResult (Err err) ->
      ({model | error=http_err_to_string err}, Cmd.none)
    PostPollResult (Ok error) ->
      ({model | submitted_answers=error=="", error=error}, Cmd.none)



----------------------------
    UrlRequest url_request ->
      case url_request of
        Browser.Internal url ->
          (model, Nav.pushUrl model.key (Url.toString url))
        Browser.External url ->
          (model, Nav.load url)
    UrlChange url ->
      let
        (route,error) = case (Parser.parse route_parser url) of
          Just route_shadowing -> (route_shadowing, "")
          Nothing -> (RouteError, "Could not parse route")
        default_model=make_default_model model.key url
        new_model={default_model | route=route, error=error}
        command=case route of
          RoutePoll poll_id -> send_get_poll poll_id
          _ -> Cmd.none
      in
        (new_model, command)

type Route
  = RouteError
  | RouteStartPoll
  | RouteShowPollLink String
  | RoutePoll String

route_parser : Parser (Route -> a) a
route_parser =
  Parser.oneOf
    [ Parser.map RouteStartPoll (Parser.s "elm_start_poll")
    , Parser.map RouteShowPollLink (Parser.s "elm_show_poll_link" </> Parser.string)
    , Parser.map RoutePoll (Parser.s "elm_poll" </> Parser.string)
    ]


-- VIEW


show_link: Url.Url -> String -> Html Msg
show_link url poll_id=
  let
    link_url = {url | path=("/elm_poll/"++poll_id), query=Nothing, fragment=Nothing}
    link_string = Url.toString link_url
  in
    div [class "container"]
    [ h1 [style "margin" ".2cm"] [text "Survey Started"]
    , div [class "col-md-12", style "margin" ".2cm", style "padding" ".2cm", style "border" ".5px solid red", style "border-radius" "4px"]
      [ p [style "font-weight" "bold", style "color" "green"] [text "Survey can now be filled at: "]
      , a [href link_string] [text link_string]
      ]
    ]

start_poll: Model -> Html Msg
start_poll model =
  div [class "container"]
  [ h1 [style "margin" ".2cm"] [text "Start Survey"]
  , div [class "col-md-12", style "margin" ".2cm", style "padding" ".2cm", style "border" ".5px solid red", style "border-radius" "4px"]
    [ div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "#Responders", onInput UpdateNumber, value (if model.poll_number==0 then "" else String.fromInt model.poll_number)] []]]
    , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "Title", onInput UpdateTitle, value model.poll_title] []]]
    , div [class "row"]
      [ div [class "btn-group col-md-4", style "margin-top" ".2cm"]
        [ button [class "btn btn-primary", disabled (not model.poll_type_is_free), onClick (ClickedFree False)] [text "Fixed"]
        , button [class "btn btn-primary", disabled model.poll_type_is_free, onClick (ClickedFree True)] [text "Free"]
        ]
      ]
    , if model.poll_type_is_free
      then div [] [p [] []]
      else div [class "row"] [div [class "col-md-4"] [textarea [rows 10, style "margin-top" ".2cm", style "margin-bottom" ".2cm", onInput UpdateQuestions, value model.poll_questions_field] []]]
    , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitPoll] [text "Submit"]]]
    , div [] [if String.length model.error>0 then p [style "font-weight" "bold", style "color" "red"] [text ("Error: "++model.error)] else div [] []]
    ]
  ]

capitalize: String -> String
capitalize s =
  (String.toUpper (String.left 1 s))++(String.dropLeft 1 s)

button_row: Model -> Int -> String -> Html Msg
button_row model index question =
  case Array.get index model.fixed_answers of
    Just state -> div [class "row"]
      [ div [class "col-md-4"]
        [ p [style "font-size" "16px", style "margin-top" ".1cm", style "color" "#AAAAAA"] [text (capitalize question)]
        , div [class "btn-group", style "margin-bottom" ".4cm"]
          [ button [class "btn btn-primary", disabled (state==2), onClick (SetFixedAnswer index 2)] [text "Yay"]
          , button [class "btn btn-primary", disabled (state==1), onClick (SetFixedAnswer index 1)] [text "Open to"]
          , button [class "btn btn-primary", disabled (state==0), onClick (SetFixedAnswer index 0)] [text "Nope"]
          ]
        ]
      ]
    Nothing -> div [] []


fill_poll: Model -> PollQuestions -> String -> Html Msg
fill_poll model questions poll_id=
  div [class "container"]
  [ h1 [style "margin" ".2cm"] [text "Fill Survey"]
  , p [style "margin-left" ".2cm"] [text <| (String.fromInt questions.polls_filled)++" out of "++(String.fromInt questions.polls_number)++" users have already answered."]
  , div [class "col-md-12", style "margin" ".2cm", style "padding" ".2cm", style "border" ".5px solid red", style "border-radius" "4px"] (
    if model.submitted_answers then
      [ p [style "font-weight" "bold", style "color" "green"]
          [ text ("This survey has been submitted successfully. The results can be seen as soon as "++(String.fromInt questions.polls_number)++" users have filled it at ")
          , a [href (Url.toString model.url)] [text (Url.toString model.url)]
          ]
      ]
    else if Array.length questions.questions==0 then
      [ div [] 
        [ div [class "row"] [div [class "col-md-4"] [p [style "font-weight" "bold", style "font-size" "20px"] [text ("Survey Title: "++(capitalize questions.title))], p [] [text "(Free entry)"]]]
        , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "User Name", onInput UpdateUserName, value model.user_name] []]]
        , div [class "row"] [div [class "col-md-4"] [textarea [rows 10, style "margin-top" ".2cm", style "margin-bottom" ".2cm", onInput UpdateFreeAnswers, value model.free_answers] []]]
        , div [class "row"] [div [class "col-md-4"] [button [onClick (ClickedSubmitAnswers poll_id)] [text "Submit"]]]
        ]
      , div [] [if String.length model.error>0 then p [style "font-weight" "bold", style "color" "red"] [text ("Error: "++model.error)] else div [] []]
      ]
    else
      [ div []
        [ div [class "row"] [div [class "col-md-4"] [p [style "font-weight" "bold", style "font-size" "20px"] [text ("Survey Title: "++(capitalize questions.title))]]]
        , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "User Name", onInput UpdateUserName, value model.user_name] []]]
        , div [] (Array.toList (Array.indexedMap (button_row model) questions.questions))
        , div [class "row"] [div [class "col-md-4"] [button [onClick (ClickedSubmitAnswers poll_id)] [text "Submit"]]]
        ]
      , div [] [if String.length model.error>0 then p [style "font-weight" "bold",  style "color" "red"] [text ("Error: "++model.error)] else div [] []]
      ]
    )
  ]

show_list: String -> Array.Array String -> Html Msg
show_list name list =
  if Array.length list>0 then
    div [style "margin" "1cm"]
    [ div [class "row"] [div [class "col-md-6", style "font-size" "20px", style "font-weight" "bold", style "color" "#AAAAAA"] [text name]]
    , div [] (Array.toList (Array.map (\x-> div [class "row"] [div [class "col-md-4", style "color" "#AAAAAA"] [text (capitalize x)]]) list))
    ]
  else
    div [] []

see_poll: Model -> PollAnswers -> Html Msg
see_poll model answers =
  div [class "container"]
  [ h1 [style "margin" ".2cm"] [text "See Survey"]
  , div [class "col-md-12", style "margin" ".2cm", style "padding" ".2cm", style "border" ".5px solid red", style "border-radius" "4px"] (
    if model.error/="" then
      [ p [style "font-weight" "bold",  style "color" "red"] [text ("Error: "++model.error)]
      ]
    else
      [ div [class "row"] [div [class "col-md-4"] [p [style "font-weight" "bold", style "font-size" "20px", style "color" "#AAAAAA"] [text ("Survey "++(capitalize answers.title))]]]
      , (show_list "Surveyed" answers.user_names)
      , (show_list "Everyone says yay to:" answers.all_yay)
      , (show_list "Everyone is at least open to trying: " answers.all_open)
      , if Array.length answers.all_yay==0 && Array.length answers.all_open==0 then div [] [text "There are no categories all surveyed are at least open to."] else div [] []
      ]
    )
  ]

show_error: String -> Html Msg
show_error error =
  div [class "container"]
  [ h1 [style "margin" ".2cm"] [text "Error Page"]
  , div [class "col-md-12", style "margin" ".2cm", style "padding" ".2cm", style "border" ".5px solid red", style "border-radius" "4px"]
    [ p [style "color" "#AAAAAA"] [text "Welcome to the error page"]
    , p [style "font-weight" "bold",  style "color" "red"] [text ("Error: "++error)]
    , a [href "/elm_start_poll"] [text "Click here to go to create survey page."]
    ]
  ]

view: Model -> Browser.Document Msg
view model =
  { title = "title"
  , body=
    [ node "link" [ rel "stylesheet", href "/static/bootstrap/css/bootstrap.min.css"] []
    , node "style" [type_ "text/css"] [text "body{background-color: black;}"]
    , case model.route of
      RouteStartPoll -> start_poll model
      RouteShowPollLink poll_id -> show_link model.url poll_id
      RoutePoll poll_id -> 
        case (model.poll_questions, model.poll_answers) of
          (Just questions, Nothing) -> fill_poll model questions poll_id
          (Nothing, Just answers) -> see_poll model answers
          _ -> if model.error=="" then div [] [text "Loading ..."]
               else show_error model.error
      RouteError -> show_error "Route error."
    ]
  }
