import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Encode as Encode
import Http
import Navigation

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
  , poll_title: String
  , poll_number: Int
  , poll_type_is_free: Bool
  , poll_questions: String
  , host: String
  , error: String
  }

init : Navigation.Location -> ( Model, Cmd Msg )
init location=
  (Model "" "" 0 False "" location.host "", Cmd.none)

-- REST

type alias StartPollOutput =
  { poll_id: String
  , error: String
  }

send_start_poll: Model -> Cmd Msg
send_start_poll model =
  let
    questions=if model.poll_type_is_free
      then ""
      else if String.length model.poll_questions==0
        then "a"
        else model.poll_questions
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
    Http.send StartPollResult (Http.post "/api/start_poll" (body) decoder)


-- UPDATE

type Msg
  = UrlChange Navigation.Location
  | UpdateTitle String
  | UpdateNumber String
  | ClickedFixed
  | ClickedFree
  | UpdateQuestions String
  | ClickedSubmitPoll
  | StartPollResult (Result Http.Error StartPollOutput)

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
    UpdateTitle new_title ->
      ({model | poll_title=new_title}, Cmd.none)
    UpdateNumber new_number ->
      case String.toInt new_number of
        Ok new_number -> ({model | poll_number=(saturate_range 0 20 new_number)}, Cmd.none)
        Err _ -> ({model | poll_number=0}, Cmd.none)
    UpdateQuestions questions ->
      ({model | poll_questions=questions}, Cmd.none)
    ClickedFree ->
      ({model | poll_type_is_free=True}, Cmd.none)
    ClickedFixed ->
      ({model | poll_type_is_free=False}, Cmd.none)
    ClickedSubmitPoll ->
      (model, send_start_poll model)
    StartPollResult (Ok start_poll_output) ->
      if start_poll_output.poll_id/="" && start_poll_output.error==""
      then ({model | error="", poll_id=start_poll_output.poll_id, poll_title="", poll_number=0, poll_type_is_free=False, poll_questions=""}, Cmd.none)
      else if start_poll_output.poll_id=="" && start_poll_output.error/=""
      then ({model | error=start_poll_output.error, poll_id=""}, Cmd.none)
      else ({model | error="Server error?"}, Cmd.none)
    StartPollResult (Err err) ->
      ({model | error="StartPollResult Error: "++(http_err_to_string err)}, Cmd.none)


-- VIEW

start_poll: Model -> Html Msg
start_poll model =
  div [class "container"]
  [ h1 [style [("margin", ".2cm")]] [text "Start Survey"]
  , div [class "col-md-12", style [("margin", ".2cm"), ("padding", ".2cm"), ("border", ".5px solid red"), ("border-radius", "4px")]]
    [ div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "#Responders", onInput UpdateNumber, value (if model.poll_number==0 then "" else toString model.poll_number)] []]]
    , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "Title", onInput UpdateTitle, value model.poll_title] []]]
    , div [class "row"]
      [ div [class "btn-group col-md-4", style [("margin-top", ".2cm")]]
        [ button [class "btn btn-primary", disabled (not model.poll_type_is_free), onClick ClickedFixed] [text "Fixed"]
        , button [class "btn btn-primary", disabled model.poll_type_is_free, onClick ClickedFree] [text "Free"]
        ]
      ]
    , if model.poll_type_is_free
      then div [] []
      else div [class "row"] [div [class "col-md-4"] [textarea [rows 10, style [("margin-top", ".2cm"), ("margin-bottom", ".2cm")], onInput UpdateQuestions, value model.poll_questions] []]]
    , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitPoll] [text "Submit"]]]
    , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
    ]
  ]

show_link: String -> Html Msg
show_link url =
  div [class "container"]
  [ h1 [style [("margin", ".2cm")]] [text "Survey Started"]
  , div [class "col-md-12", style [("margin", ".2cm"), ("padding", ".2cm"), ("border", ".5px solid red"), ("border-radius", "4px")]]
    [ p [] [text "Find it at: ", a [href url] [text url]] 
    ]
  ]

view: Model -> Html Msg
view model =
  div []
  [node "link" [ rel "stylesheet", href "/static/bootstrap/css/bootstrap.min.css"] []
  , node "style" [type_ "text/css"] [text "body{background-color: black;}"]
  , if model.poll_id==""
    then start_poll model
    else show_link <| "http://"++model.host++"/elm/fill_poll?poll_id="++model.poll_id
  ]
