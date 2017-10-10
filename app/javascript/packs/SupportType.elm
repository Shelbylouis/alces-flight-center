module SupportType exposing (..)

import Json.Decode as D


type SupportType
    = Managed
    | Advice


decoder : D.Decoder SupportType
decoder =
    let
        stringToSupportType =
            \string ->
                case string of
                    "managed" ->
                        D.succeed Managed

                    "advice" ->
                        D.succeed Advice

                    other ->
                        D.fail ("Unknown support type: " ++ other)
    in
    D.string |> D.andThen stringToSupportType
