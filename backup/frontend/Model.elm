module Model exposing (..)

import Http
--import Time exposing (Time)

--type Site
--  = ChooseName
--  | Chat

--type alias Message =
--  { name: String
--  , message: String
--  }

--type alias IncommingMessages =
--  { last_message: Int
--  , messages: List Message
--  }

--type Msg
--  = SetName String
--  | OkName
--  | SetMessage String
--  | GoToChooseName
--  | SendMessage
--  | SendMessageReturn (Result Http.Error Int)
--  | TimeToCheckForMessages Time
--  | GetMessagesReturn (Result Http.Error IncommingMessages)

--type alias Model =
--  { name: String
--  , message: String
--  , messages: List Message
--  , status_string: String
--  , site: Site
--  }

--init: (Model, Cmd Msg)
--init = (Model "" "" [] "" ChooseName, Cmd.none)

type NavBarState
  = NavReports
  | NavFill
  | NavInvites -- See received and sent. Also make new

type Msg
  = SetNavBar NavBarState
  | LogIn
  | LogOut
  | SetNick String
  | SetPass String
  | CheckCredentialsReturn (Result Http.Error Bool)
  | GetPluginNamesReturn (Result Http.Error (List String))
  | SelectPlugin String
  | GetPluginFillingReturn (Result Http.Error (List String))

type alias Model =
  { logged_in: Bool
  , nav_bar_state: NavBarState
  , nick: String
  , pass: String
  , plugin_names: List String
  , selected_plugin: Maybe String
  , plugin_filling: List String
  , error_string: String
  }

init: (Model, Cmd Msg)
--init = (Model False NavReports "" "" [] "", Cmd.none)
init = (Model True NavFill "" "" [] Nothing [] "", Cmd.none)