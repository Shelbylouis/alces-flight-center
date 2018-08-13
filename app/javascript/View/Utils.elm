module View.Utils exposing (..)

import Field exposing (Field)
import Html exposing (..)
import Html.Attributes exposing (..)
import State exposing (State)


supportEmailLink : Html msg
supportEmailLink =
    let
        email =
            "support@alces-software.com"
    in
    a
        [ "mailto:" ++ email |> href
        , target "_blank"
        ]
        [ text email ]


nothing : Html msg
nothing =
    text ""


showIfParentFieldSelected : State -> Field -> Html msg -> Html msg
showIfParentFieldSelected state field html =
    if Field.parentFieldHasBeenSelected state field then
        html
    else
        nothing
