module Cluster
    exposing
        ( Cluster
        , Id(..)
        , asServicesIn
        , decoder
        , extractId
        , setSelectedCategory
        , setSelectedComponent
        , setSelectedIssue
        , setSelectedService
        , setSelectedServiceWhere
        , setServices
        )

import Category
import Component exposing (Component)
import Issue
import Json.Decode as D
import SelectList exposing (Position(..), SelectList)
import SelectList.Extra
import Service exposing (Service)
import SupportType exposing (SupportType)
import Utils


type alias Cluster =
    { id : Id
    , name : String
    , components : SelectList Component
    , services : SelectList Service
    , supportType : SupportType
    , chargingInfo : Maybe String
    , credits : Int
    }


type Id
    = Id Int


decoder : D.Decoder Cluster
decoder =
    D.map7 Cluster
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "components" (SelectList.Extra.nameOrderedDecoder Component.decoder))
        (D.field "services" (SelectList.Extra.nameOrderedDecoder Service.decoder))
        (D.field "supportType" SupportType.decoder)
        (D.field "chargingInfo" (D.nullable D.string))
        (D.field "credits" D.int)


extractId : Cluster -> Int
extractId cluster =
    case cluster.id of
        Id id ->
            id


setSelectedComponent : SelectList Cluster -> Component.Id -> SelectList Cluster
setSelectedComponent clusters componentId =
    SelectList.Extra.nestedSelect
        clusters
        .components
        asComponentsIn
        (Utils.sameId componentId)


asComponentsIn : Cluster -> SelectList Component -> Cluster
asComponentsIn cluster components =
    { cluster | components = components }


setSelectedService : SelectList Cluster -> Service.Id -> SelectList Cluster
setSelectedService clusters serviceId =
    setSelectedServiceWhere clusters (Utils.sameId serviceId)


setSelectedServiceWhere : SelectList Cluster -> (Service -> Bool) -> SelectList Cluster
setSelectedServiceWhere clusters shouldSelect =
    SelectList.Extra.nestedSelect
        clusters
        .services
        asServicesIn
        shouldSelect


setSelectedCategory : SelectList Cluster -> Category.Id -> SelectList Cluster
setSelectedCategory clusters categoryId =
    let
        updateService =
            SelectList.Extra.mapSelected (Service.setSelectedCategory categoryId)
    in
    SelectList.Extra.updateNested
        clusters
        .services
        asServicesIn
        updateService


setSelectedIssue : SelectList Cluster -> Issue.Id -> SelectList Cluster
setSelectedIssue clusters issueId =
    let
        updateService =
            SelectList.Extra.mapSelected (Service.setSelectedIssue issueId)
    in
    SelectList.Extra.updateNested
        clusters
        .services
        asServicesIn
        updateService


setServices : SelectList Service -> Cluster -> Cluster
setServices services cluster =
    { cluster | services = services }


asServicesIn : Cluster -> SelectList Service -> Cluster
asServicesIn =
    flip setServices
