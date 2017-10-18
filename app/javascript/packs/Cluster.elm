module Cluster exposing (..)

import Component exposing (Component)
import Json.Decode as D
import SelectList exposing (SelectList)
import Utils


type alias Cluster =
    { id : Id
    , name : String
    , components : SelectList Component
    }


type Id
    = Id Int


decoder : D.Decoder Cluster
decoder =
    D.map3 Cluster
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "components" (Utils.selectListDecoder Component.decoder))


extractId : Cluster -> Int
extractId cluster =
    case cluster.id of
        Id id ->
            id
