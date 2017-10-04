module CaseCategory exposing (..)


type alias CaseCategory =
    { id : Id
    , name : String
    , requiresComponent : Bool
    }


type Id
    = Id Int
