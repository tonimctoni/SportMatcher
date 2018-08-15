module Rest exposing (..)

import Model exposing (..)
import Http
--import Array
import Json.Decode as Decode
import Json.Encode as Encode
----elm-package install elm-lang/http

send_start_poll: Model -> Cmd Msg
send_start_poll model =
  let
    questions=if model.start_poll_form_type_is_free
      then ""
      else if String.length model.start_poll_form_questions==0
        then "a"
        else model.start_poll_form_questions
    body =
      [ ("poll_number", Encode.int model.start_poll_form_number)
      , ("poll_title", Encode.string model.start_poll_form_title)
      , ("poll_questions", Encode.string questions)
      ]
      |> Encode.object
      |> Http.jsonBody

    decoder = Decode.map2 StartPollOutput
      (Decode.field "poll_id" Decode.string)
      (Decode.field "error" Decode.string)
  in
    Http.send StartPollResult (Http.post "/start_poll" (body) decoder)



----poll_name_exists: Model -> Cmd Msg
----poll_name_exists model =
----  let
----    body =
----      model.name
----      |> Encode.string
----      |> Http.jsonBody

----    return_bool_decoder = Decode.bool
----  in
----    Http.send PollNameExistsReturn (Http.post "/poll_name_exists" (body) return_bool_decoder)

--get_poll: Model -> Cmd Msg
--get_poll model =
--  let
--    body =
--      model.poll_name
--      |> Encode.string
--      |> Http.jsonBody

--    return_gotten_poll_decoder = Decode.map3 GottenPoll
--      (Decode.field "title" Decode.string)
--      (Decode.field "questions" (Decode.array Decode.string))
--      (Decode.field "error_string" Decode.string)

--    --return_nullable_gotten_poll_decoder = Decode.nullable return_gotten_poll_decoder
--  in
--    Http.send GetPollReturn (Http.post "/get_poll" (body) return_gotten_poll_decoder)


--fill_free_entry_poll: Model -> Cmd Msg
--fill_free_entry_poll model =
--  let
--    body =
--      [ ("poll_name", Encode.string model.poll_name)
--      , ("user_name", Encode.string model.user_name)
--      , ("answers", Encode.string model.free_answers)
--      ]
--      |> Encode.object
--      |> Http.jsonBody

--    return_string_decoder = Decode.string
--  in
--    Http.send FillFreeEntryPollReturn (Http.post "/fill_free_entry_poll" (body) return_string_decoder)


--fill_poll: Model -> Cmd Msg
--fill_poll model =
--  let
--    body =
--      [ ("poll_name", Encode.string model.poll_name)
--      , ("user_name", Encode.string model.user_name)
--      , ("answers", Encode.array (Array.map Encode.int model.fixed_answers))
--      ]
--      |> Encode.object
--      |> Http.jsonBody

--    return_string_decoder = Decode.string
--  in
--    Http.send FillFixedPollReturn (Http.post "/fill_poll" (body) return_string_decoder)


--get_poll_results: Model -> Cmd Msg
--get_poll_results model =
--  let
--    body =
--      model.poll_name
--      |> Encode.string
--      |> Http.jsonBody

--    return_poll_result_decoder = Decode.map5 PollResult
--      (Decode.field "poll_title" Decode.string)
--      (Decode.field "user_names" (Decode.list Decode.string))
--      (Decode.field "all_yay" (Decode.list Decode.string))
--      (Decode.field "all_open" (Decode.list Decode.string))
--      (Decode.field "error_string" Decode.string)

--  in
--    Http.send GetPollResultReturn (Http.post "/get_poll_results" (body) return_poll_result_decoder)

