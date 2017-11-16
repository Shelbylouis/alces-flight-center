module View.Utils exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


type AlertType
    = Danger
    | Warning


alert : AlertType -> List (Html msg) -> Html msg
alert alertType children =
    let
        alertClass =
            toString alertType
                |> String.toLower
                |> (\suffix -> "alert-" ++ suffix)

        classes =
            "alert " ++ alertClass ++ " alert-dismissable fade show"
    in
    div
        [ class classes
        , attribute "role" "alert"
        ]
        children
