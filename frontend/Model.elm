module Model exposing (..)

import Navigation
import Regex

import Http
--import Array

--type alias PollResult =
--  { title: String
--  , user_names: List String
--  , all_yay: List String
--  , all_open: List String
--  , error: String
--  }

--type alias GottenPoll =
--  { title: String
--  , questions: Array.Array String
--  , error: String
--  }

--type NavBarState
--  = NavGreeting
--  | NavStartPoll
--  | NavFillPoll
--  | NavSeePoll
--  | NavMessage

--type Msg
--  = SetNavBar NavBarState
--  | UpdatePollName String
--  | UpdateTitle String
--  | UpdateNumber String
--  | ClickedFree
--  | ClickedFixed
--  | UpdateQuestions String
--  | ClickedSubmitPoll
--  | StartPollReturn (Result Http.Error String)
--  --| PollNameExistsReturn (Result Http.Error Bool)
--  | ClickedGetPoll
--  | GetPollReturn (Result Http.Error GottenPoll)
--  | UpdateFreeAnswers String
--  | ClickedSubmitFreeAnswers
--  | UpdateUserName String
--  | FillFreeEntryPollReturn (Result Http.Error String)
--  | ClickedSubmitFixedAnswers
--  | SetFixedAnswer Int Int
--  | FillFixedPollReturn (Result Http.Error String)
--  | ClickedGetPollResult
--  | GetPollResultReturn (Result Http.Error PollResult)

--type alias Model =
--  { navbar_state: NavBarState
--  , poll_name: String
--  , number: Int
--  , title: String
--  , qtype_is_free: Bool
--  , questions: String
--  , error: String
--  , message: String
--  , gotten_questions: Array.Array String
--  , free_answers: String
--  , user_name: String
--  , fixed_answers: Array.Array Int
--  , user_names: List String
--  , all_yay: List String
--  , all_open: List String
--  }

--init: (Model, Cmd Msg)
--init = (Model NavGreeting "" 0 "" False "" "" "" Array.empty "" "" Array.empty [] [] [], Cmd.none)



type Page
  = StartPollPage
  | ShowPollLinkPage
  | FillPollPage
  | ShowPollPage

type alias StartPollOutput =
  { poll_id: String
  , error: String
  }

type Msg
  = UrlChange Navigation.Location
  | UpdateTitle String
  | UpdateNumber String
  | ClickedFixed
  | ClickedFree
  | UpdateQuestions String
  | ClickedSubmitPoll
  | StartPollResult (Result Http.Error StartPollOutput)

type alias Model =
  { page: Page
  , error: String
  , poll_id: String
-- -- --> Poll form
  , poll_title: String
  , poll_number: Int
  , poll_type_is_free: Bool
  , poll_questions: String
  }


--get_var_value: String -> String -> Maybe String
--get_var_value search varname=
--  let
--    regex=Regex.regex <| ""++varname++"=(\\w+)"
--    matches=Regex.find (Regex.AtMost 1) regex search
--  in
--    List.head matches
--    |> Maybe.andThen (\match -> List.head match.submatches)
--    |> Maybe.andThen (\submatch -> submatch)

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
  --let
  --  --(poll_id, page)=case get_poll_id_from_var location.search of
  --  --  Nothing -> ("",StartPollPage)
  --  --  Maybe poll_id -> (poll_id,)
  --in
    ( Model
      StartPollPage (toString location) ""
-- -- --> Poll Form
      "" 0 False ""
      , Cmd.none)