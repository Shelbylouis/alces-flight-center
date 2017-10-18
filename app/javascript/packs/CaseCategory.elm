module CaseCategory exposing (..)

import Json.Decode as D


type alias CaseCategory =
    { id : Id
    , name : String
    , requiresComponent : Bool
    }


type Id
    = Id Int


decoder : D.Decoder CaseCategory
decoder =
    D.map3 CaseCategory
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
