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

--message_input: Model -> Html Msg
--message_input model =
--  div [style [("padding", "10pt")]]
--  [ p [style [("font-weight", "bold"), ("color", "green")]] [text (model.name++": "), input [style [("width", "75%")], type_ "text", placeholder "Message", onInput SetMessage, onEnter SendMessage, value model.message] []]
--  , button [onClick SendMessage, disabled (String.length model.message<1)] [text "Send"]
--  ]

--format_message: Message -> Html Msg
--format_message message =
--  div [style [("padding", "2pt"), ("color", "magenta")]] [node "b" [] [text (message.name++": ")], text message.message]

--message_list_div: Model -> Html Msg
--message_list_div model =
--  div
--  [style [("background-color", "rgba(123, 123, 123, 0.5)"), ("width", "65%"), ("margin", "20pt"), ("border-radius", "6px")]]
--  (List.map format_message model.messages)

--chat_div: Model -> Html Msg
--chat_div model =
--  div []
--  [ p [style [("font-weight", "bold"), ("color", "red")]] [text model.status_string]
--  , button [style [("left", "4cm")], onClick GoToChooseName] [text "Change name"]
--  , text model.status_string
--  , message_input model
--  , message_list_div model
--  ]

--choose_name_div: Model -> Html Msg
--choose_name_div model =
--  div [class "choose_name_form_container_class"]
--  [ h1 [class "choose_name_form_title_class"] [text "Choose Name"]
--  , input [class "choose_name_input_class", type_ "text", placeholder "Name", onInput SetName, onEnter OkName] []
--  , br [] []
--  , div [] [button [onClick OkName] [text "Ok"]]
--  , if String.length model.status_string == 0 then br [] [] else p [style [("font-weight", "bold"), ("color", "red")]] [text model.status_string]
--  ]

--view: Model -> Html Msg
--view model =
--  div []
--  [ node "link" [ rel "stylesheet", href "/mycss.css"] []
--  , case model.site of
--      ChooseName -> choose_name_div model
--      Chat -> chat_div model
--  ]

--nav_bar: NavBarState -> Html Msg
--nav_bar nav_bar_state =
--  nav [class "navbar navbar-inverse"]
--  [ div [class "container-fluid"]
--    [ div [class "navbar-header"]
--      [ a [class "navbar-brand", style [("color", "purple")], href "javascript:;"] [text "Sport Matcher"]
--      ]
--    , ul [class "nav navbar-nav"]
--      [ li (if nav_bar_state==NavReports then [class "active"] else []) [a [href "javascript:;", onClick (SetNavBar NavReports)] [text "Reports"]]
--      , li (if nav_bar_state==NavFill then [class "active"] else []) [a [href "javascript:;", onClick (SetNavBar NavFill)] [text "Fill"]]
--      , li (if nav_bar_state==NavInvites then [class "active"] else []) [a [href "javascript:;", onClick (SetNavBar NavInvites)] [text "Invite"]]
--      ]
--    , ul [class "nav navbar-nav navbar-right"]
--      [ li [] [a [href "javascript:;", onClick LogOut] [span [class "glyphicon glyphicon-log-out"] [], text " Unlogin"]]
--      ]
--    ]
--  ]
----, ("padding", ".75cm")
--log_in: Model -> Html Msg
--log_in model=
--  div [style 
--  [ ("position", "fixed")
--  , ("top", "50%")
--  , ("left", "50%")
--  , ("transform", "translate(-50%, -50%)")
--  , ("background-color", "black")
--  , ("border-color", "#444444")
--  , ("border-style", "solid")
--  , ("border-width", "medium")
--  , ("padding-left", ".75cm")
--  , ("padding-right", ".75cm")
--  , ("padding-bottom", ".75cm")
--  , ("text-align", "center")
--  ]]
--  [ h1 [style [("text-align", "left")]] [text "Login"]
--  , if String.length model.error_string == 0 then div [] [] else h5 [] [text model.error_string]
--  , input [type_ "text", placeholder "Name", onInput SetNick] []
--  , br [] []
--  , input [type_ "password", placeholder "Password", onInput SetPass, onEnter LogIn] []
--  , br [] []
--  , button [onClick LogIn, style [("margin-top", ".5cm")]] [text "Ok"]
--  ]

--plugin_buttons: Model -> Html Msg
--plugin_buttons model =
--  div
--    [class "col-md-2", style [("text-align", "center"), ("margin", ".1cm")]]
--    (List.map (\x -> div [] [button [class "btn", style [("margin", ".25cm"), ("width", "3cm")], onClick (SelectPlugin x)] [text x]]) model.plugin_names)

--plugin_filling : Model -> Html Msg
--plugin_filling model =
--  case model.selected_plugin of
--    Nothing -> div [] []
--    Just selected_plugin -> div [class "col-md-4", style [("border-left", ".075cm dashed #555555")]]
--      [ div [] []
--      , div [] (List.map (\x -> h2 [class "text-info"] [text x]) model.plugin_filling)
--      ]

--nav_fill: Model -> Html Msg
--nav_fill model =
--  div [class "container", style [("margin", ".2cm"), ("padding", ".2cm")]]
--  [ div [class "row"]
--    [ plugin_buttons model
--    , plugin_filling model
--    ]
--  ]

--view: Model -> Html Msg
--view model =
--  div []
--  [node "link" [ rel "stylesheet", href "/bootstrap/css/bootstrap.min.css"] []
--  , node "style" [type_ "text/css"] [text "body{background-image: url('/darkness640.jpg');}"]
--  , if model.logged_in then
--      div []
--      [ nav_bar model.nav_bar_state
--      , if String.length model.error_string == 0 then div [] [] else h5 [] [text model.error_string]
--      , case model.nav_bar_state of
--        NavReports -> text "asd"
--        NavFill -> nav_fill model
--        NavInvites -> text "zxc"
--      ]
--    else
--      log_in model
--  ]

navbar: NavBarState -> Html Msg
navbar navbar_state =
  nav [class "navbar navbar-inverse"]
  [ div [class "container-fluid"]
    [ div [class "navbar-header"]
      [ a [class "navbar-brand", style [("color", "purple")], href "javascript:;", onClick (SetNavBar NavGreeting)] [text "Matcher"]
      ]
    , ul [class "nav navbar-nav"]
      [ li (if navbar_state==NavStartPoll then [class "active disabled"] else []) [a [href "javascript:;", onClick (SetNavBar NavStartPoll)] [text "Start Poll"]]
      , li (if navbar_state==NavFillPoll then [class "active disabled"] else []) [a [href "javascript:;", onClick (SetNavBar NavFillPoll)] [text "Fill Poll"]]
      , li (if navbar_state==NavSeePoll then [class "active disabled"] else []) [a [href "javascript:;", onClick (SetNavBar NavSeePoll)] [text "See Poll"]]
      ]
    --, ul [class "nav navbar-nav navbar-right"]
    --  [ li [] [a [href "javascript:;", onClick LogOut] [span [class "glyphicon glyphicon-log-out"] [], text " Unlogin"]]
    --  ]
    ]
  ]

greeting: Html Msg
greeting =
  div []
  [ h1 [] [text "greeting"]
  ]

start_poll: Model -> Html Msg
start_poll model =
  div [class "container"]
  [ h1 [style [("margin", ".2cm")]] [text "Start Poll"]
  , div [class "col-md-6", style [("margin", ".2cm"), ("padding", ".2cm"), ("border", ".5px solid red")]]
    [ div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "Poll Name", onInput UpdatePollName, value model.poll_name] []]]
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
        else div [class "row"] [div [class "col-md-4"] [textarea [rows 10, style [("margin-top", ".2cm"), ("margin-bot", ".2cm")], onInput UpdateQuestions, value model.questions] []]]
    , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitPoll] [text "Submit"]]]
    , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
    ]
  ]

fill_poll: Model -> Html Msg
fill_poll model =
  div [class "container"]
  [ h1 [style [("margin", ".2cm")]] [text "Fill Poll"]
  , div [class "col-md-6", style [("margin", ".2cm"), ("padding", ".2cm"), ("border", ".5px solid red")]] (
    if String.length model.title==0 then
      [ div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "Poll Name", onInput UpdatePollName, onEnter ClickedGetPoll, value model.poll_name] []]]
      , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedGetPoll] [text "Get Poll"]]]
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    else if Array.length model.gotten_questions==0 then
      [ div [] 
        [ div [class "row"] [div [class "col-md-4"] [p [style [("font-weight", "bold"), ("font-size", "20px")]] [text model.title], p [] [text "(Free entry)"]]]
        , div [class "row"] [div [class "col-md-4"] [input [type_ "text", placeholder "User Name", onInput UpdateUserName, value model.user_name] []]]
        , div [class "row"] [div [class "col-md-4"] [textarea [rows 10, style [("margin-top", ".2cm"), ("margin-bot", ".2cm")], onInput UpdateFreeAnswers, value model.free_answers] []]]
        , div [class "row"] [div [class "col-md-4"] [button [onClick ClickedSubmitFreeAnswers] [text "Submit"]]]
        ]
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    else
      [ div []
        [ div [class "row"] [div [class "col-md-4"] [p [style [("font-weight", "bold"), ("font-size", "20px")]] [text model.title]]]
        ]
      , div [] [if String.length model.error>0 then p [style [("font-weight", "bold"), ("color", "red")]] [text model.error] else div [] []]
      ]
    )
  ]

see_poll: Html Msg
see_poll =
  div []
  [ h1 [] [text "see_poll"]
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
      NavSeePoll -> see_poll
      NavMessage -> see_message model.message
    ]
  , div [] [text (toString model)]
  ]