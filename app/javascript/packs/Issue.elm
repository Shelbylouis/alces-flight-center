module Issue exposing (..)

import Json.Decode as D


type alias Issue =
    { id : Id
    , name : String
    , requiresComponent : Bool
    }


type Id
    = Id Int


decoder : D.Decoder Issue
decoder =
    D.map3 Issue
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
