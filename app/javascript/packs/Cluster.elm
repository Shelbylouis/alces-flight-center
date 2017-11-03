module Cluster exposing (..)

import Component exposing (Component)
import Json.Decode as D
import SelectList exposing (Position(..), SelectList)
import Service exposing (Service)
import SupportType exposing (SupportType)
import Utils


type alias Cluster =
    { id : Id
    , name : String
    , components : SelectList Component
    , services : SelectList Service
    , supportType : SupportType
    }


type Id
    = Id Int


decoder : D.Decoder Cluster
decoder =
    D.map5 Cluster
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "components" (Utils.selectListDecoder Component.decoder))
        (D.field "services" (Utils.selectListDecoder Service.decoder))
        (D.field "supportType" SupportType.decoder)


extractId : Cluster -> Int
extractId cluster =
    case cluster.id of
        Id id ->
            id



-- XXX de-duplicate following two functions; also
-- Main.handleChangeSelectedIssue is similar.


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


setSelectedService : SelectList Cluster -> Service.Id -> SelectList Cluster
setSelectedService clusters serviceId =
    let
        updateSelectedClusterSelectedService =
            \position ->
                \cluster ->
                    if position == Selected then
                        { cluster
                            | services =
                                SelectList.select (Utils.sameId serviceId) cluster.services
                        }
                    else
                        cluster
    in
    SelectList.mapBy updateSelectedClusterSelectedService clusters
