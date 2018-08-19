import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Encode as Encode
import Http
import Navigation
import Regex
import Array

main =
  Navigation.program UrlChange
    { init = init
    , view = view
    , update = update
    , subscriptions = \_-> Sub.none
    }


-- MODEL

type alias Model =
  { poll_id: String
  , title: String
  , user_name: String
  , gotten_questions: Array.Array String
  , fixed_answers: Array.Array Int
  , free_answers: String
  , filled_by_all: Bool
  , submitted: Bool
  , host: String
  , error: String
  }

get_poll_id_from_var: String -> Maybe String
get_poll_id_from_var search=
  let
    regex=Regex.regex <| "poll_id=([0123456789abcdefABCDEF]+)"
    matches=Regex.find (Regex.AtMost 1) regex search
  in
    List.head matches
    |> Maybe.andThen (\match -> List.head match.submatches)
    |> Maybe.andThen (\submatch -> submatch)

init : Navigation.Location -> ( Model, Cmd Msg )
init location=
  let
    poll_id = Maybe.withDefault "" <| get_poll_id_from_var location.search
    error = if poll_id=="" then "Error: Could not retrieve poll id from url parameters." else ""
    command = if poll_id=="" then Cmd.none else send_get_poll poll_id 
  in
    (Model poll_id "" "" Array.empty Array.empty "" False False location.host error, command)


-- REST

type alias GottenPoll =
  { title: String
  , questions: Array.Array String
  , polls_filled: Int
  , polls_number: Int
  , error: String
  }

send_get_poll: String -> Cmd Msg
send_get_poll poll_id=
  let
    decoder = Decode.map5 GottenPoll
      (Decode.field "title" Decode.string)
      (Decode.field "questions" (Decode.array Decode.string))
      (Decode.field "polls_filled" Decode.int)
      (Decode.field "polls_number" Decode.int)
      (Decode.field "error" Decode.string)
    url="/api/get_poll/"++poll_id
    get_request=Http.get url decoder
  in
    Http.send GetPollResult get_request

send_fill_poll: Model -> Cmd Msg
send_fill_poll model =
  let
    body =
      [ ("user_name", Encode.string model.user_name)
      , ("poll_id", Encode.string model.poll_id)
      , ("answers", Encode.array (Array.map Encode.int model.fixed_answers))
      ]
      |> Encode.object
      |> Http.jsonBody

    return_string_decoder = Decode.string
  in
    Http.send FillFixedPollReturn (Http.post "/api/fill_poll" (body) return_string_decoder)

send_fill_free_entry_poll: Model -> Cmd Msg
send_fill_free_entry_poll model =
  let
    body =
      [ ("user_name", Encode.string model.user_name)
      , ("poll_id", Encode.string model.poll_id)
      , ("answers", Encode.string model.free_answers)
      ]
      |> Encode.object
      |> Http.jsonBody

    return_string_decoder = Decode.string
  in
    Http.send FillFreeEntryPollReturn (Http.post "/api/fill_free_entry_poll" (body) return_string_decoder)


-- UPDATE

type Msg
  = UrlChange Navigation.Location
  | GetPollResult (Result Http.Error GottenPoll)
  | UpdateUserName String
  | SetFixedAnswer Int Int
  | UpdateFreeAnswers String
  | ClickedSubmitFreeAnswers
  | ClickedSubmitFixedAnswers
  | FillFixedPollReturn (Result Http.Error String)
  | FillFreeEntryPollReturn (Result Http.Error String)

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
    Http.BadPayload s _ -> "BadPayload("++s++")"

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    UrlChange location ->
      (model, Cmd.none)
    UpdateUserName user_name ->
      ({model | user_name=user_name}, Cmd.none)
    SetFixedAnswer index state ->
      ({model | fixed_answers=Array.set index state model.fixed_answers}, Cmd.none)
    UpdateFreeAnswers free_answers ->
      ({model | free_answers=free_answers}, Cmd.none)
    ClickedSubmitFixedAnswers -> (model, send_fill_poll model)
    ClickedSubmitFreeAnswers -> (model, send_fill_free_entry_poll model)
    GetPollResult (Ok gotten_poll) ->
      if gotten_poll.error/="" then
        ({model | error="Error: "++gotten_poll.error, poll_id=""}, Cmd.none)
      else if gotten_poll.polls_filled<gotten_poll.polls_number then
        ({model | title=gotten_poll.title, gotten_questions=gotten_poll.questions, fixed_answers=Array.repeat (Array.length gotten_poll.questions) 3, error=""}, Cmd.none)
      else if gotten_poll.polls_filled==gotten_poll.polls_number then
        ({model | filled_by_all=True}, Cmd.none)
      else ({model | error="Server error?"}, Cmd.none)
    GetPollResult (Err err) ->
      ({model | error="GetPollResult Error: "++(http_err_to_string err), poll_id=""}, Cmd.none)
    FillFixedPollReturn (Ok err)->
      if err=="" then
        ({model | submitted=True}, Cmd.none)
      else
        ({model | error=err}, Cmd.none)
    FillFixedPollReturn (Err err)->
      ({model | error="FillFixedPollReturn Error: "++(http_err_to_string err), poll_id=""}, Cmd.none)
    FillFreeEntryPollReturn (Ok err)->
      if err=="" then
        ({model | submitted=True}, Cmd.none)
      else
        ({model | error=err}, Cmd.none)
    FillFreeEntryPollReturn (Err err)->
      ({model | error="FillFreeEntryPollReturn Error: "++(http_err_to_string err), poll_id=""}, Cmd.none)


-- VIEW

capitalize: String -> String
capitalize s =
  (String.toUpper (String.left 1 s))++(String.dropLeft 1 s)

button_row: Model -> Int -> String -> Html Msg
button_row model index question =
  case Array.get index model.fixed_answers of
    Just state -> div [class "row"]
      [ div [class "col-md-4"]
        [ p [style [("font-size", "16px"), ("margin-top", ".1cm")]] [text (capitalize question)]
        , div [class "btn-group", style [("margin-bottom", ".4cm")]]
          [ button [class "btn btn-primary", disabled (state==2), onClick (SetFixedAnswer index 2)] [text "Yay"]
          , button [class "btn btn-primary", disabled (state==1), onClick (SetFixedAnswer index 1)] [text "Open to"]
          , button [class "btn btn-primary", disabled (state==0), onClick (SetFixedAnswer index 0)] [text "Nope"]
          ]
        ]
      ]
    Nothing -> div [] []

fill_poll: Model -> Html Msg
fill_poll model =
  div [class "container"]
  [ h1 [style [("margin", ".2cm")]] [text "Fill Survey"]
  , div [class "col-md-12", style [("margin", ".2cm"), ("padding", ".2cm"), ("border", ".5px solid red"), ("border-radius", "4px")]] (
    if model.poll_id=="" then
      [ p [style [("font-weight", "bold"), ("color", "red")]] [text model.error]
      ]
    else if model.submitted then
      [ p [style [("font-weight", "bold"), ("color", "green")]]
        [ text "This poll has been submitted successfully. To see the results, go to "
        , a [href ("http://"++model.host++"/elm/see_poll?poll_id="++model.poll_id)] [text ("http://"++model.host++"/elm/see_poll?poll_id="++model.poll_id)]
        ]
      ]
    else if model.filled_by_all then
      [ p [style [("font-weight", "bold"), ("color", "green")]]
        [ text "This poll has been filled out by enough people already. To see the results, go to "
        , a [href ("http://"++model.host++"/elm/see_poll?poll_id="++model.poll_id)] [text ("http://"++model.host++"/elm/see_poll?poll_id="++model.poll_id)]
        ]
      ]
    else if Array.length model.gotten_questions==0 then
      [ div [] 
        [ div [class "row"] [div [class "col-md-4"] [p [style [("font-weight", "bold"), ("font-size", "20px")]] [text ("Polling "++(capitalize model.title))], p [] [text "(Free entry)"]]]
        , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "User Name", onInput UpdateUserName, value model.user_name] []]]
        , div [class "row"] [div [class "col-md-4"] [textarea [rows 10, style [("margin-top", ".2cm"), ("margin-bottom", ".2cm")], onInput UpdateFreeAnswers, value model.free_answers] []]]
        , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitFreeAnswers] [text "Submit"]]]
        ]
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    else
      [ div []
        [ div [class "row"] [div [class "col-md-4"] [p [style [("font-weight", "bold"), ("font-size", "20px")]] [text ("Polling "++(capitalize model.title))]]]
        , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "User Name", onInput UpdateUserName, value model.user_name] []]]
        , div [] (Array.toList (Array.indexedMap (button_row model) model.gotten_questions))
        , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitFixedAnswers] [text "Submit"]]]
        ]
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    )
  ]

view: Model -> Html Msg
view model =
  div []
  [node "link" [ rel "stylesheet", href "/static/bootstrap/css/bootstrap.min.css"] []
  , node "style" [type_ "text/css"] [text "body{background-color: black;}"]
  , fill_poll model
  ]

