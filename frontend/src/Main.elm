import Browser
import Browser.Navigation as Nav
import Url
import Html exposing (text)
import Url.Parser as Parser exposing (Parser, (</>))

main =
  Browser.application { init=init, view=view, update=update, subscriptions=\_-> Sub.none, onUrlRequest=UrlRequest, onUrlChange=UrlChange}

type alias Model =
  { key: Nav.Key
  , url: Url.Url
  , route: Route
  , error: String
  }

type Msg = MsgInstance | UrlRequest Browser.UrlRequest | UrlChange Url.Url

make_default_model: Nav.Key -> Url.Url -> Model
make_default_model key url = Model key url RouteError ""

init: () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
  (make_default_model key url , Nav.pushUrl key "/elm/start_poll")

update: Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
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
  | RouteFillPoll String
  | RouteSeePoll String

route_parser : Parser (Route -> a) a
route_parser =
  Parser.oneOf
    [ Parser.map RouteStartPoll (Parser.s "elm/start_poll")
    , Parser.map RouteFillPoll (Parser.s "elm/fill_poll" </> Parser.string)
    , Parser.map RouteFillPoll (Parser.s "elm/see_poll" </> Parser.string)
    ]


route_to_string: Route -> String
route_to_string route =
  case route of
    RouteError -> "RouteError"
    RouteStartPoll -> "RouteStartPoll"
    RouteFillPoll s-> "RouteFillPoll" ++ " " ++ s
    RouteSeePoll s-> "RouteSeePoll" ++ " " ++ s

view: Model -> Browser.Document Msg
view model = 
  { title = "title"
  , body=
    [ text <| route_to_string model.route
    , text model.error
    ]
  }