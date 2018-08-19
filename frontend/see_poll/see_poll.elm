import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Http
import Navigation
import Regex

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
  , user_names: List String
  , all_yay: List String
  , all_open: List String
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
    command = if poll_id=="" then Cmd.none else send_get_poll_results poll_id
  in
    (Model poll_id "" [] [] [] error, command)

-- REST

type alias PollResult =
  { title: String
  , user_names: List String
  , all_yay: List String
  , all_open: List String
  , error: String
  }

send_get_poll_results: String -> Cmd Msg
send_get_poll_results poll_id =
  let
    decoder = Decode.map5 PollResult
      (Decode.field "title" Decode.string)
      (Decode.field "user_names" (Decode.list Decode.string))
      (Decode.field "all_yay" (Decode.list Decode.string))
      (Decode.field "all_open" (Decode.list Decode.string))
      (Decode.field "error" Decode.string)
    url="/api/get_poll_results/"++poll_id
    get_request=Http.get url decoder

  in
    Http.send GetPollResultReturn get_request


-- UPDATE

type Msg
  = UrlChange Navigation.Location
  | GetPollResultReturn (Result Http.Error PollResult)

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
    GetPollResultReturn (Ok poll_result) ->
      ({model | title=poll_result.title, user_names=poll_result.user_names, all_yay=poll_result.all_yay, all_open=poll_result.all_open, error=poll_result.error}, Cmd.none)
    GetPollResultReturn (Err err) ->
      ({model | error="GetPollResultReturn Error: "++(http_err_to_string err)}, Cmd.none)


-- VIEW

capitalize: String -> String
capitalize s =
  (String.toUpper (String.left 1 s))++(String.dropLeft 1 s)

show_list: String -> List String -> Html Msg
show_list name list =
  if List.length list>0 then
    div [style [("margin", "1cm")]]
    [ div [class "row"] [div [class "col-md-6", style [("font-size", "20px"), ("font-weight", "bold")]] [text name]]
    , div [] (List.map (\x-> div [class "row"] [div [class "col-md-4"] [text (capitalize x)]]) list)
    ]
  else
    div [] []

see_poll: Model -> Html Msg
see_poll model =
  div [class "container"]
  [ h1 [style [("margin", ".2cm")]] [text "See Survey"]
  , div [class "col-md-12", style [("margin", ".2cm"), ("padding", ".2cm"), ("border", ".5px solid red"), ("border-radius", "4px")]] (
    if model.error/="" then
      [ p [style [("font-weight", "bold"), ("color", "red")]] [text model.error]
      ]
    else
      [ div [class "row"] [div [class "col-md-4"] [p [style [("font-weight", "bold"), ("font-size", "20px")]] [text ("Survey "++(capitalize model.title))]]]
      , (show_list "Surveyed" model.user_names)
      , (show_list "Everyone says yay to:" model.all_yay)
      , (show_list "Everyone is at least open to trying: " model.all_open)
      , if List.length model.all_yay==0 && List.length model.all_open==0 then div [] [text "There are no categories all surveyed are at least open to."] else div [] []
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    )
  ]

view: Model -> Html Msg
view model =
  div []
  [node "link" [ rel "stylesheet", href "/static/bootstrap/css/bootstrap.min.css"] []
  , node "style" [type_ "text/css"] [text "body{background-color: black;}"]
  , see_poll model
  ]
