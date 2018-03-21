module Rest exposing (..)

import Model exposing (..)
import Http
import Array
import Json.Decode as Decode
import Json.Encode as Encode
--elm-package install elm-lang/http

--send_message: Model -> Cmd Msg
--send_message model =
--  let
--    body =
--      [ ("name", Encode.string model.name)
--      , ("message", Encode.string model.message)
--      ]
--      |> Encode.object
--      |> Http.jsonBody

--    return_int_decoder = Decode.int
--  in
--    Http.send SendMessageReturn (Http.post "/post_message" (body) return_int_decoder)

--get_messages: Model -> Cmd Msg
--get_messages model =
--  let
--    body =
--      [("last_message", Encode.int (List.length model.messages))]
--      |> Encode.object
--      |> Http.jsonBody

--    message_decoder: Decode.Decoder Message
--    message_decoder = Decode.map2 Message
--      (Decode.field "name" Decode.string)
--      (Decode.field "message" Decode.string)

--    return_incomming_messages_decoder: Decode.Decoder IncommingMessages
--    return_incomming_messages_decoder = Decode.map2 IncommingMessages
--      (Decode.field "last_message" Decode.int)
--      (Decode.field "new_messages" (Decode.list message_decoder))
--  in
--    Http.send GetMessagesReturn (Http.post "/get_messages" (body) return_incomming_messages_decoder)

--check_credentials: Model -> Cmd Msg
--check_credentials model =
--  let
--    body =
--      [ ("nick", Encode.string model.nick)
--      , ("pass", Encode.string model.pass)
--      ]
--      |> Encode.object
--      |> Http.jsonBody

--    return_bool_decoder = Decode.bool
--  in
--    Http.send CheckCredentialsReturn (Http.post "/check_credentials" (body) return_bool_decoder)

--get_plugin_names: Cmd Msg
--get_plugin_names =
--  let
--    return_plugin_names_decoder: Decode.Decoder (List String)
--    return_plugin_names_decoder = 
--      Decode.list Decode.string
--  in
--    Http.send GetPluginNamesReturn (Http.get "/get_plugin_names" return_plugin_names_decoder)

--get_plugin_filling: String -> Cmd Msg
--get_plugin_filling selected_plugin =
--  let
--    body =
--      selected_plugin
--      |> Encode.string
--      |> Http.jsonBody

--    return_plugin_filling_decoder: Decode.Decoder (List String)
--    return_plugin_filling_decoder = Decode.list Decode.string
--  in
--    Http.send GetPluginFillingReturn (Http.post "/get_plugin_filling" (body) return_plugin_filling_decoder)


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