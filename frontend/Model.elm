module Model exposing (..)

import Http
import Array
--import Time exposing (Time)

type alias PollResult =
  { title: String
  , user_names: List String
  , all_yay: List String
  , all_open: List String
  , error: String
  }

type alias GottenPoll =
  { title: String
  , questions: Array.Array String
  , error: String
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
  | GetPollReturn (Result Http.Error GottenPoll)
  | UpdateFreeAnswers String
  | ClickedSubmitFreeAnswers
  | UpdateUserName String
  | FillFreeEntryPollReturn (Result Http.Error String)
  | ClickedSubmitFixedAnswers
  | SetFixedAnswer Int Int
  | FillFixedPollReturn (Result Http.Error String)
  | ClickedGetPollResult
  | GetPollResultReturn (Result Http.Error PollResult)

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
  , user_names: List String
  , all_yay: List String
  , all_open: List String
  }

init: (Model, Cmd Msg)
init = (Model NavGreeting "" 0 "" False "" "" "" Array.empty "" "" Array.empty [] [] [], Cmd.none)