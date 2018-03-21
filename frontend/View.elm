module View exposing (view)

import Model exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, on, keyCode)
import Json.Decode as Decode
import Array

onEnter : Msg -> Attribute Msg
onEnter msg =
  let
    isEnter code =
      if code == 13 then
        Decode.succeed msg
      else
        Decode.fail "not ENTER"
  in
    on "keydown" (Decode.andThen isEnter keyCode)

capitalize: String -> String
capitalize s =
  (String.toUpper (String.left 1 s))++(String.dropLeft 1 s)

navbar: NavBarState -> Html Msg
navbar navbar_state =
  nav [class "navbar navbar-inverse"]
  [ div [class "container-fluid"]
    [ div [class "navbar-header"]
      [ a [class "navbar-brand", style [("color", "purple")], href "javascript:;", onClick (SetNavBar NavGreeting)] [text "Matcher"]
      ]
    , ul [class "nav navbar-nav"]
      [ li (if navbar_state==NavStartPoll then [class "active disabled"] else []) [a [href "javascript:;", onClick (SetNavBar NavStartPoll)] [text "Start Survey"]]
      , li (if navbar_state==NavFillPoll then [class "active disabled"] else []) [a [href "javascript:;", onClick (SetNavBar NavFillPoll)] [text "Fill Survey"]]
      , li (if navbar_state==NavSeePoll then [class "active disabled"] else []) [a [href "javascript:;", onClick (SetNavBar NavSeePoll)] [text "See Survey"]]
      ]
    --, ul [class "nav navbar-nav navbar-right"]
    --  [ li [] [a [href "javascript:;", onClick LogOut] [span [class "glyphicon glyphicon-log-out"] [], text " Unlogin"]]
    --  ]
    ]
  ]

greeting: Html Msg
greeting =
  div []
  [ h1 [] [text ""]
  ]

start_poll: Model -> Html Msg
start_poll model =
  div [class "container"]
  [ h1 [style [("margin", ".2cm")]] [text "Start Survey"]
  , div [class "col-md-12", style [("margin", ".2cm"), ("padding", ".2cm"), ("border", ".5px solid red"), ("border-radius", "4px")]]
    [ div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "Survey Name", onInput UpdatePollName, value model.poll_name] []]]
    , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "Min. Responders", onInput UpdateNumber, value (if model.number==0 then "" else toString model.number)] []]]
    , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "Title", onInput UpdateTitle, value model.title] []]]
    , div [class "row"]
      [ div [class "btn-group col-md-4", style [("margin-top", ".2cm")]]
        [ button [class "btn btn-primary", disabled (not model.qtype_is_free), onClick ClickedFixed] [text "Fixed"]
        , button [class "btn btn-primary", disabled model.qtype_is_free, onClick ClickedFree] [text "Free"]
        ]
      ]
    , if model.qtype_is_free
        then div [] []
        else div [class "row"] [div [class "col-md-4"] [textarea [rows 10, style [("margin-top", ".2cm"), ("margin-bottom", ".2cm")], onInput UpdateQuestions, value model.questions] []]]
    , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitPoll] [text "Submit"]]]
    , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
    ]
  ]

button_row: Model -> Int -> String -> Html Msg
button_row model index question =
  case Array.get index model.fixed_answers of
    Just state -> div [class "row"]
      [ div [class "col-md-4"]
        [ p [style [("font-size", "16px"), ("font-color", "purple"), ("margin-top", ".1cm")]] [text (capitalize question)]
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
    if String.length model.title==0 then
      [ div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "Survey Name", onInput UpdatePollName, onEnter ClickedGetPoll, value model.poll_name] []]]
      , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedGetPoll] [text "Get Survey"]]]
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    else if Array.length model.gotten_questions==0 then
      [ div [] 
        [ div [class "row"] [div [class "col-md-4"] [p [style [("font-weight", "bold"), ("font-size", "20px")]] [text ("Polling "++model.title)], p [] [text "(Free entry)"]]]
        , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "User Name", onInput UpdateUserName, value model.user_name] []]]
        , div [class "row"] [div [class "col-md-4"] [textarea [rows 10, style [("margin-top", ".2cm"), ("margin-bottom", ".2cm")], onInput UpdateFreeAnswers, value model.free_answers] []]]
        , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitFreeAnswers] [text "Submit"]]]
        ]
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    else
      [ div []
        [ div [class "row"] [div [class "col-md-4"] [p [style [("font-weight", "bold"), ("font-size", "20px")]] [text ("Polling "++model.title)]]]
        , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "User Name", onInput UpdateUserName, value model.user_name] []]]
        , div [] (Array.toList (Array.indexedMap (button_row model) model.gotten_questions))
        , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitFixedAnswers] [text "Submit"]]]
        ]
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    )
  ]

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
    if String.length model.title==0 then
      [ div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "Survey Name", onInput UpdatePollName, onEnter ClickedGetPollResult, value model.poll_name] []]]
      , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedGetPollResult] [text "Get Survey Results"]]]
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    else
      [ div [class "row"] [div [class "col-md-4"] [p [style [("font-weight", "bold"), ("font-size", "20px")]] [text ("Survey "++model.title)]]]
      , (show_list "Users" model.user_names)
      , (show_list "Everyone says yay to:" model.all_yay)
      , (show_list "Everyone is at least open to trying: " model.all_open)
      , if List.length model.all_yay==0 && List.length model.all_open==0 then div [] [text "There are no categories all surveyed are at least open to."] else div [] []
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    )
  ]

see_message: String -> Html Msg
see_message message =
  div []
  [ p [style [("font-weight", "bold"), ("color", "red"), ("font-size", "20px")]] [text message]
  ]

view: Model -> Html Msg
view model =
  div []
  [node "link" [ rel "stylesheet", href "/bootstrap/css/bootstrap.min.css"] []
  --, node "style" [type_ "text/css"] [text "body{background-image: url('/darkness640.jpg');}"]
  , div []
    [ navbar model.navbar_state
    , case model.navbar_state of
      NavGreeting -> greeting
      NavStartPoll -> start_poll model
      NavFillPoll -> fill_poll model
      NavSeePoll -> see_poll model
      NavMessage -> see_message model.message
    ]
  --, div [] [text (toString model)]
  ]