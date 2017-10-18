module Cluster exposing (..)

import Component exposing (Component)
import Json.Decode as D
import SelectList exposing (SelectList)
import SupportType exposing (SupportType)
import Utils


type alias Cluster =
    { id : Id
    , name : String
    , components : SelectList Component
    , supportType : SupportType
    }


type Id
    = Id Int


decoder : D.Decoder Cluster
decoder =
    D.map4 Cluster
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "components" (Utils.selectListDecoder Component.decoder))
        (D.field "supportType" SupportType.decoder)


extractId : Cluster -> Int
extractId cluster =
    case cluster.id of
        Id id ->
            id
