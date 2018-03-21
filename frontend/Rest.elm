module Rest exposing (..)

import Model exposing (..)
import Http
import Array
import Json.Decode as Decode
import Json.Encode as Encode
--elm-package install elm-lang/http

start_poll: Model -> Cmd Msg
start_poll model =
  let
    questions=if model.qtype_is_free
      then ""
      else if String.length model.questions==0
        then "a"
        else model.questions
    body =
      [ ("name", Encode.string model.poll_name)
      , ("number", Encode.int model.number)
      , ("title", Encode.string model.title)
      , ("questions", Encode.string questions)
      ]
      |> Encode.object
      |> Http.jsonBody

    return_string_decoder = Decode.string
  in
    Http.send StartPollReturn (Http.post "/start_poll" (body) return_string_decoder)


--poll_name_exists: Model -> Cmd Msg
--poll_name_exists model =
--  let
--    body =
--      model.name
--      |> Encode.string
--      |> Http.jsonBody

--    return_bool_decoder = Decode.bool
--  in
--    Http.send PollNameExistsReturn (Http.post "/poll_name_exists" (body) return_bool_decoder)

get_poll: Model -> Cmd Msg
get_poll model =
  let
    body =
      model.poll_name
      |> Encode.string
      |> Http.jsonBody

    return_gotten_poll_decoder = Decode.map2 GottenPoll
      (Decode.field "title" Decode.string)
      (Decode.field "questions" (Decode.array Decode.string))

    return_nullable_gotten_poll_decoder = Decode.nullable return_gotten_poll_decoder
  in
    Http.send GetPollReturn (Http.post "/get_poll" (body) return_nullable_gotten_poll_decoder)


fill_free_entry_poll: Model -> Cmd Msg
fill_free_entry_poll model =
  let
    body =
      [ ("poll_name", Encode.string model.poll_name)
      , ("user_name", Encode.string model.user_name)
      , ("answers", Encode.string model.free_answers)
      ]
      |> Encode.object
      |> Http.jsonBody

    return_string_decoder = Decode.string
  in
    Http.send FillFreeEntryPollReturn (Http.post "/fill_free_entry_poll" (body) return_string_decoder)


fill_poll: Model -> Cmd Msg
fill_poll model =
  let
    body =
      [ ("poll_name", Encode.string model.poll_name)
      , ("user_name", Encode.string model.user_name)
      , ("answers", Encode.array (Array.map Encode.int model.fixed_answers))
      ]
      |> Encode.object
      |> Http.jsonBody

    return_string_decoder = Decode.string
  in
    Http.send FillFixedPollReturn (Http.post "/fill_poll" (body) return_string_decoder)


get_poll_results: Model -> Cmd Msg
get_poll_results model =
  let
    body =
      model.poll_name
      |> Encode.string
      |> Http.jsonBody

    return_gotten_poll_decoder = Decode.map5 PollResult
      (Decode.field "poll_title" Decode.string)
      (Decode.field "user_names" (Decode.list Decode.string))
      (Decode.field "all_yay" (Decode.list Decode.string))
      (Decode.field "all_open" (Decode.list Decode.string))
      (Decode.field "error_string" Decode.string)

  in
    Http.send GetPollResultReturn (Http.post "/get_poll_results" (body) return_gotten_poll_decoder)
