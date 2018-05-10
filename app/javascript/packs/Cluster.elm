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
        , setSelectedTier
        , setServices
        , updateSelectedIssue
        )

import Category
import Component exposing (Component)
import Issue exposing (Issue)
import Issues
import Json.Decode as D
import SelectList exposing (Position(..), SelectList)
import SelectList.Extra
import Service exposing (Service)
import SupportType exposing (SupportType)
import Tier
import Utils


type alias Cluster =
    { id : Id
    , name : String
    , components : SelectList Component
    , services : SelectList Service
    , supportType : SupportType
    , chargingInfo : Maybe String
    , credits : Int
    , motd : String
    }


type Id
    = Id Int


decoder : D.Decoder Cluster
decoder =
    D.map8 Cluster
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "components" (SelectList.Extra.nameOrderedDecoder Component.decoder))
        (D.field "services" (SelectList.Extra.nameOrderedDecoder Service.decoder))
        (D.field "supportType" SupportType.decoder)
        (D.field "chargingInfo" (D.nullable D.string))
        (D.field "credits" D.int)
        (D.field "motd" D.string)


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
    SelectList.Extra.nestedSelect
        clusters
        .services
        asServicesIn
        (Utils.sameId serviceId)


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


setSelectedTier : SelectList Cluster -> Tier.Id -> SelectList Cluster
setSelectedTier clusters tierId =
    updateSelectedIssue clusters (Issue.selectTier tierId)


updateSelectedIssue : SelectList Cluster -> (Issue -> Issue) -> SelectList Cluster
updateSelectedIssue clusters changeIssue =
    let
        updateCluster =
            \cluster ->
                SelectList.Extra.mapSelected updateService cluster.services
                    |> asServicesIn cluster

        updateService =
            \service ->
                updateIssues service.issues
                    |> Service.asIssuesIn service

        updateIssues =
            Issues.mapIssue changeIssue

        updateCategory =
            \category ->
                SelectList.Extra.mapSelected changeIssue category.issues
                    |> Category.asIssuesIn category
    in
    SelectList.Extra.mapSelected updateCluster clusters


setServices : SelectList Service -> Cluster -> Cluster
setServices services cluster =
    { cluster | services = services }


asServicesIn : Cluster -> SelectList Service -> Cluster
asServicesIn =
    flip setServices
