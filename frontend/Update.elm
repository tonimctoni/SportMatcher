module Update exposing (update)

import Rest exposing (..)
import Model exposing (..)
import Http
import Array

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
    SetNavBar navbar_state -> if navbar_state==model.navbar_state
      then (model, Cmd.none)
      else ({model | 
      navbar_state=navbar_state,
      poll_name="",
      number=0,
      title="",
      qtype_is_free=False,
      questions="",
      error="",
      message="",
      gotten_questions=Array.empty,
      free_answers="",
      user_name="",
      fixed_answers=Array.empty,
      user_names=[],
      all_yay=[],
      all_open=[]
      }, Cmd.none)
    UpdatePollName poll_name -> ({model | poll_name=poll_name}, Cmd.none)
    UpdateTitle title -> ({model | title=title}, Cmd.none)
    UpdateQuestions questions -> ({model | questions=questions}, Cmd.none)
    UpdateNumber number -> case String.toInt number of
      Ok number -> ({model | number=if number>20 then 20 else number}, Cmd.none)
      Err _ -> ({model | number=0}, Cmd.none)
    ClickedFree -> ({model | qtype_is_free=True}, Cmd.none)
    ClickedFixed -> ({model | qtype_is_free=False}, Cmd.none)
    ClickedSubmitPoll -> (model, start_poll model)
    StartPollReturn (Ok return_string) -> if String.length return_string>0
      then ({model | error="Error: "++return_string}, Cmd.none)
      else ({model | navbar_state=NavMessage, message="Poll was added successfully. Its name is: "++model.poll_name}, Cmd.none)
    StartPollReturn (Err err) -> ({model | error="StartPollReturn Error: "++(http_err_to_string err)}, Cmd.none)
    ClickedGetPoll -> (model, get_poll model)
    GetPollReturn (Ok (Just gotten_poll)) -> ({model | title=gotten_poll.title, gotten_questions=gotten_poll.questions, fixed_answers=Array.repeat (Array.length gotten_poll.questions) 3, error=""}, Cmd.none)
    GetPollReturn (Ok Nothing) -> ({model | error="Error: A poll by that name does not exist (or there is a serious server error)."}, Cmd.none)
    GetPollReturn (Err err) -> ({model | error="GetPollReturn Error: "++(http_err_to_string err)}, Cmd.none)
    UpdateUserName user_name -> ({model | user_name=user_name}, Cmd.none)
    UpdateFreeAnswers free_answers -> ({model | free_answers=free_answers}, Cmd.none)
    ClickedSubmitFreeAnswers -> (model, fill_free_entry_poll model)
    FillFreeEntryPollReturn (Ok return_string) -> if String.length return_string>0
      then ({model | error="Error: "++return_string}, Cmd.none)
      else ({model | navbar_state=NavMessage, message="Answers to poll "++model.poll_name++" were submitted successfully."}, Cmd.none)
    FillFreeEntryPollReturn (Err err) -> ({model | error="FillFreeEntryPollReturn Error: "++(http_err_to_string err)}, Cmd.none)
    ClickedSubmitFixedAnswers -> (model, fill_poll model)
    SetFixedAnswer index state -> ({model | fixed_answers=Array.set index state model.fixed_answers}, Cmd.none)
    FillFixedPollReturn (Ok return_string) -> if String.length return_string>0
      then ({model | error="Error: "++return_string}, Cmd.none)
      else ({model | navbar_state=NavMessage, message="Answers to poll "++model.poll_name++" were submitted successfully."}, Cmd.none)
    FillFixedPollReturn (Err err) -> ({model | error="FillFixedPollReturn Error: "++(http_err_to_string err)}, Cmd.none)
    ClickedGetPollResult -> (model, get_poll_results model)
    GetPollResultReturn (Ok poll_result) -> if String.length poll_result.error>0
      then ({model | error="Error: "++poll_result.error}, Cmd.none)
      else ({model | title=poll_result.title, user_names=poll_result.user_names, all_yay=poll_result.all_yay, all_open=poll_result.all_open}, Cmd.none)
    GetPollResultReturn (Err err) -> ({model | error="GetPollResultReturn Error: "++(http_err_to_string err)}, Cmd.none)