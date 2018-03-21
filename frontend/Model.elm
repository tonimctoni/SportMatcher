module Model exposing (..)

import Http
import Array
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

--type NavBarState
--  = NavReports
--  | NavFill
--  | NavInvites -- See received and sent. Also make new

--type Msg
--  = SetNavBar NavBarState
--  | LogIn
--  | LogOut
--  | SetNick String
--  | SetPass String
--  | CheckCredentialsReturn (Result Http.Error Bool)
--  | GetPluginNamesReturn (Result Http.Error (List String))
--  | SelectPlugin String
--  | GetPluginFillingReturn (Result Http.Error (List String))

--type alias Model =
--  { logged_in: Bool
--  , nav_bar_state: NavBarState
--  , nick: String
--  , pass: String
--  , plugin_names: List String
--  , selected_plugin: Maybe String
--  , plugin_filling: List String
--  , error_string: String
--  }

--init: (Model, Cmd Msg)
----init = (Model False NavReports "" "" [] "", Cmd.none)
--init = (Model True NavFill "" "" [] Nothing [] "", Cmd.none)

type alias GottenPoll =
  { title: String
  , questions: Array.Array String
  }

type NavBarState
  = NavGreeting
  | NavStartPoll
  | NavFillPoll
  | NavSeePoll
  | NavMessage

type Msg
  = SetNavBar NavBarState
  | UpdatePollName String
  | UpdateTitle String
  | UpdateNumber String
  | ClickedFree
  | ClickedFixed
  | UpdateQuestions String
  | ClickedSubmitPoll
  | StartPollReturn (Result Http.Error String)
  --| PollNameExistsReturn (Result Http.Error Bool)
  | ClickedGetPoll
  | GetPollReturn (Result Http.Error (Maybe GottenPoll))
  | UpdateFreeAnswers String
  | ClickedSubmitFreeAnswers
  | UpdateUserName String
  | FillFreeEntryPollReturn (Result Http.Error String)
  | ClickedSubmitFixedAnswers
  | SetFixedAnswer Int Int
  | FillFixedPollReturn (Result Http.Error String)

type alias Model =
  { navbar_state: NavBarState
  , poll_name: String
  , number: Int
  , title: String
  , qtype_is_free: Bool
  , questions: String
  , error: String
  , message: String
  , gotten_questions: Array.Array String
  , free_answers: String
  , user_name: String
  , fixed_answers: Array.Array Int
  }

init: (Model, Cmd Msg)
init = (Model NavSeePoll "" 0 "" False "" "" "" Array.empty "" "" Array.empty, Cmd.none)