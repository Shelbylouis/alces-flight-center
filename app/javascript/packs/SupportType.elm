module SupportType exposing (..)

import Json.Decode as D


type SupportType
    = Managed
    | Advice
      -- `advice-only` only makes sense for Issues; indicates the Issue can only
      -- be associated with an `advice` Component.
    | AdviceOnly


type alias HasSupportType a =
    { a | supportType : SupportType }


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

                    "advice-only" ->
                        D.succeed AdviceOnly

                    other ->
                        D.fail ("Unknown support type: " ++ other)
    in
    D.string |> D.andThen stringToSupportType


isManaged : HasSupportType a -> Bool
isManaged x =
    x.supportType == Managed


isAdvice : HasSupportType a -> Bool
isAdvice x =
    x.supportType == Advice
