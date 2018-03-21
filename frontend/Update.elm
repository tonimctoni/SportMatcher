module Update exposing (update)

import Rest exposing (..)
import Model exposing (..)
import Http

--choose_name: Model -> (Model, Cmd Msg)
--choose_name model =
--  if String.length model.name>0 && String.length model.name<16 then
--    ({model | site=Chat, status_string=""}, get_messages model)
--  else
--    ({model | status_string="Name must have between 1 and 15 characters."}, Cmd.none)

--http_err_to_string: Http.Error -> String
--http_err_to_string err =
--  case err of
--    Http.BadUrl s -> "BadUrl("++s++")"
--    Http.Timeout -> "Timeout"
--    Http.NetworkError -> "NetworkError"
--    Http.BadStatus _ -> "BadStatus"
--    Http.BadPayload s _ -> "BadPayload("++s++")"

--handle_incomming_messages: Model -> IncommingMessages -> Model
--handle_incomming_messages model incomming_messages =
--  if List.length incomming_messages.messages==0 then
--    model
--  else
--    if incomming_messages.last_message==List.length model.messages then
--      {model | messages=List.append incomming_messages.messages model.messages}
--    else
--      model

--update: Msg -> Model -> (Model, Cmd Msg)
--update msg model =
--  case msg of
--    SetName s -> ({model | name=s}, Cmd.none)
--    SetMessage s -> ({model | message=s}, Cmd.none)
--    OkName -> choose_name model
--    GoToChooseName -> ({model | site=ChooseName, status_string="", name=""}, Cmd.none)
--    SendMessage -> (model, if (String.length model.message<1) then Cmd.none else send_message model)
--    SendMessageReturn (Ok _) -> ({model | message=""}, get_messages model)
--    SendMessageReturn (Err err) -> ({model | status_string="SendMessage Error: "++(http_err_to_string err)}, Cmd.none)
--    TimeToCheckForMessages _ -> (model, get_messages model)
--    GetMessagesReturn (Ok incomming_messages) -> (handle_incomming_messages model incomming_messages, Cmd.none)
--    GetMessagesReturn (Err err) -> ({model | status_string="GetMessages Error: "++(http_err_to_string err)}, Cmd.none)

--nav_bar_state_to_needed_cmd: NavBarState -> Cmd Msg
--nav_bar_state_to_needed_cmd new_nav_bar_state =
--  case new_nav_bar_state of
--    NavReports -> Cmd.none
--    NavFill -> get_plugin_names
--    NavInvites -> Cmd.none

--update: Msg -> Model -> (Model, Cmd Msg)
--update msg model =
--  case msg of
--    SetNavBar nav_bar_state -> ({model | nav_bar_state=nav_bar_state, error_string=""}, nav_bar_state_to_needed_cmd nav_bar_state) -- maybe load fresh data here
--    SetNick nick -> ({model | nick=nick, error_string=""}, Cmd.none)
--    SetPass pass -> ({model | pass=pass, error_string=""}, Cmd.none)
--    LogIn -> (model, check_credentials model)
--    LogOut -> ({model | nick="", pass="", error_string="" , logged_in=False}, Cmd.none)
--    CheckCredentialsReturn (Ok ok) -> (if ok then {model | logged_in=True, error_string=""} else {model | logged_in=False, error_string="Erroneous credentials"}, Cmd.none)
--    CheckCredentialsReturn (Err err) -> ({model | error_string="CheckCredentialsReturn Error: "++(http_err_to_string err)}, Cmd.none)
--    GetPluginNamesReturn (Ok plugin_name_list) -> ({model | plugin_names=plugin_name_list}, Cmd.none)
--    GetPluginNamesReturn (Err err) -> ({model | error_string="GetPluginNamesReturn Error: "++(http_err_to_string err)}, Cmd.none)
--    SelectPlugin name -> ({model | selected_plugin=Just name}, get_plugin_filling name)
--    GetPluginFillingReturn (Ok plugin_filling) -> ({model | plugin_filling=plugin_filling}, Cmd.none)
--    GetPluginFillingReturn (Err err) -> ({model | error_string="GetPluginFillingReturn Error: "++(http_err_to_string err)}, Cmd.none)

--validate_start_poll_form: Model -> Bool
--validate_start_poll_form model =
--  if String.length model.un_error==0 && model.number>1 && model.number<=1000 then
--    True
--  else
--    False

http_err_to_string: Http.Error -> String
http_err_to_string err =
  case err of
    Http.BadUrl s -> "BadUrl("++s++")"
    Http.Timeout -> "Timeout"
    Http.NetworkError -> "NetworkError"
    Http.BadStatus _ -> "BadStatus"
    Http.BadPayload s _ -> "BadPayload("++s++")"

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SetNavBar navbar_state -> ({model | 
      navbar_state=navbar_state,
      name="",
      number=0,
      title="",
      qtype_is_free=False,
      questions="",
      start_poll_error="",
      message=""
      }, Cmd.none)
    UpdateName name -> ({model | name=name}, Cmd.none)
    UpdateTitle title -> ({model | title=title}, Cmd.none)
    UpdateQuestions questions -> ({model | questions=questions}, Cmd.none)
    UpdateNumber number -> case String.toInt number of
      Ok number -> ({model | number=number}, Cmd.none)
      Err _ -> ({model | number=0}, Cmd.none)
    ClickedFree -> ({model | qtype_is_free=True}, Cmd.none)
    ClickedFixed -> ({model | qtype_is_free=False}, Cmd.none)
    ClickedSubmitPoll -> (model, start_poll model)
    StartPollReturn (Ok return_string) -> if String.length return_string>0
      then ({model | start_poll_error="Error: "++return_string}, Cmd.none)
      else ({model | navbar_state=NavMessage, message="Poll was added successfully. Its name is: "++model.name}, Cmd.none)
    StartPollReturn (Err err) -> ({model | start_poll_error="StartPollReturn Error: "++(http_err_to_string err)}, Cmd.none)