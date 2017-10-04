module Cluster exposing (..)


type alias Cluster =
    { id : Id
    , name : String
    }


type Id
    = Id Int
