module Component exposing (..)

import Json.Decode as D


type alias Component =
    { id : Id
    , name : String
    }


type Id
    = Id Int


decoder : D.Decoder Component
decoder =
    D.map2 Component
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
