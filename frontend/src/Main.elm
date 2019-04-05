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
  , poll_questions: String
  }

make_default_model: Nav.Key -> Url.Url -> Model
make_default_model key url = Model key url RouteError "" "" 0 False ""

init: () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
  (make_default_model key url , Nav.replaceUrl key <| Url.toString url)


-- REST (ish)

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
    Http.post {url="/api/start_poll", body=body, expect=Http.expectJson StartPollResult decoder}
    --Http.request {method="PUT", headers=[Http.header "Content-Type" "application/json"], url="/api/start_poll", body=body, expect=Http.expectJson StartPollResult decoder, timeout=Nothing, tracker=Nothing}


-- UPDATE

type Msg
  = MsgInstance
  | UrlRequest Browser.UrlRequest
  | UrlChange Url.Url
  | UpdateTitle String
  | UpdateNumber String
  | ClickedFree Bool
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
      ({model | poll_questions=questions}, Cmd.none)
    ClickedFree free ->
      ({model | poll_type_is_free=free}, Cmd.none)
    ClickedSubmitPoll ->
      (model, send_start_poll model)
    StartPollResult (Err err) ->
      ({model | error=http_err_to_string err}, Cmd.none)
    StartPollResult (Ok start_poll_output) ->
      if start_poll_output.error/="" then ({model | error=start_poll_output.error}, Cmd.none)
      else (model, Nav.pushUrl model.key ("/elm_show_poll_link/"++start_poll_output.poll_id))

--------------------------------
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
      in
        (new_model, Cmd.none)
    _ -> (model, Cmd.none)

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

route_to_string: Route -> String
route_to_string route =
  case route of
    RouteError -> "RouteError"
    RouteStartPoll -> "RouteStartPoll"
    RouteShowPollLink s-> "RouteShowPollLink" ++ " " ++ s
    RoutePoll s-> "RoutePoll" ++ " " ++ s


show_link: Url.Url -> String -> Html Msg
show_link url poll_id=
  let
    link_url = {url | path=("/elm_poll/"++poll_id), query=Nothing, fragment=Nothing}
    link_string = Url.toString link_url
  in
    div []
    [ text "The poll can be found at:"
    , a [href link_string] [text link_string]
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
      else div [class "row"] [div [class "col-md-4"] [textarea [rows 10, style "margin-top" ".2cm", style "margin-bottom" ".2cm", onInput UpdateQuestions, value model.poll_questions] []]]
    , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitPoll] [text "Submit"]]]
    , div [] [if String.length model.error>0 then p [style "font-weight" "bold", style "color" "red"] [text ("Error: "++model.error)] else div [] []]
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
      _ -> div [] []
    ]
  }