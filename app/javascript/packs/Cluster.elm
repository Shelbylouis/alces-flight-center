module Cluster exposing (..)

import Json.Decode as D


type alias Cluster =
    { id : Id
    , name : String
    }


type Id
    = Id Int


decoder : D.Decoder Cluster
decoder =
    D.map2 Cluster
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
