module View.Utils exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


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
