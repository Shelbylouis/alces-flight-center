module Cluster exposing (..)

import Component exposing (Component)
import Json.Decode as D
import SelectList exposing (Position(..), SelectList)
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


setSelectedComponent : SelectList Cluster -> Component.Id -> SelectList Cluster
setSelectedComponent clusters componentId =
    let
        updateSelectedClusterSelectedComponent =
            \position ->
                \cluster ->
                    if position == Selected then
                        { cluster
                            | components =
                                SelectList.select (Utils.sameId componentId) cluster.components
                        }
                    else
                        cluster
    in
    SelectList.mapBy updateSelectedClusterSelectedComponent clusters
