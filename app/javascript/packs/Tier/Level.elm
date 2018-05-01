module Tier.Level
    exposing
        ( Level(..)
        , asInt
        , description
        , fromInt
        )


type Level
    = Zero
    | One
    | Two
    | Three


asInt : Level -> Int
asInt level =
    case level of
        Zero ->
            0

        One ->
            1

        Two ->
            2

        Three ->
            3


fromInt : Int -> Result String Level
fromInt int =
    case int of
        0 ->
            Ok Zero

        1 ->
            Ok One

        2 ->
            Ok Two

        3 ->
            Ok Three

        _ ->
            Err <| "Invalid level: " ++ toString int


description : Level -> String
description level =
    let
        humanTierDescription =
            case level of
                Zero ->
                    "Guides"

                One ->
                    "Tool"

                Two ->
                    "Routine Maintenance"

                Three ->
                    "General Support"

        tierNumberPrefix =
            toString (asInt level) ++ ":"
    in
    String.join " "
        [ "Tier", tierNumberPrefix, humanTierDescription ]
