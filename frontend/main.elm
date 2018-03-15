import Html exposing (program)
--import Time exposing (Time, second)
import Model exposing (..)
import Update exposing (update)
import View exposing (view)

--subscriptions: Model -> Sub Msg
--subscriptions model=
--  if model.site==Chat then Time.every second TimeToCheckForMessages else Sub.none
--  --Time.every second TimeToCheckForMessages
--  --Sub.none

subscriptions: Model -> Sub Msg
subscriptions model =
  Sub.none

main: Program Never Model Msg
main =
  program
    { init=init
    , view=view
    , update=update
    , subscriptions=subscriptions
    }