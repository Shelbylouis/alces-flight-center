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
import DrillDownSelectList exposing (DrillDownSelectList)
import Issue exposing (Issue)
import Issues
import Json.Decode as D
import Json.Decode.Pipeline as P
import Maybe.Extra
import Service exposing (Service)
import SupportType exposing (SupportType)
import Tier
import Utils


type alias Cluster =
    { id : Id
    , name : String
    , components : DrillDownSelectList Component
    , services : DrillDownSelectList Service
    , supportType : SupportType
    , chargingInfo : Maybe String
    , motd : String
    , motdHtml : String
    }


type Id
    = Id Int


decoder : D.Decoder Cluster
decoder =
    D.field "motd" (D.nullable D.string)
        |> D.andThen decodeWithMotd


decodeWithMotd : Maybe String -> D.Decoder Cluster
decodeWithMotd maybeMotd =
    let
        motd =
            Maybe.withDefault "" maybeMotd

        serviceDecoder =
            Service.decoder motd
    in
    P.decode Cluster
        |> P.required "id" (D.int |> D.map Id)
        |> P.required "name" D.string
        |> P.required "components"
            (DrillDownSelectList.nameOrderedDecoder Component.decoder)
        |> P.required "services"
            (DrillDownSelectList.nameOrderedDecoder serviceDecoder)
        |> P.required "supportType" SupportType.decoder
        |> P.required "chargingInfo"
            (D.nullable D.string
                |> D.map
                    -- If `chargingInfo` is an empty/just whitespace String,
                    -- then we want to handle it in the same way as when it's
                    -- null (i.e. display the default charging info), so
                    -- convert it to be Nothing in these cases too.
                    (Maybe.map
                        (\chargingInfo ->
                            if String.trim chargingInfo |> String.isEmpty then
                                Nothing
                            else
                                Just chargingInfo
                        )
                        >> Maybe.Extra.join
                    )
            )
        |> P.hardcoded motd
        |> P.required "motdHtml" D.string


extractId : Cluster -> Int
extractId cluster =
    case cluster.id of
        Id id ->
            id


setSelectedComponent :
    DrillDownSelectList Cluster
    -> Component.Id
    -> DrillDownSelectList Cluster
setSelectedComponent clusters componentId =
    DrillDownSelectList.nestedSelect
        clusters
        .components
        asComponentsIn
        (Utils.sameId componentId)


asComponentsIn : Cluster -> DrillDownSelectList Component -> Cluster
asComponentsIn cluster components =
    { cluster | components = components }


setSelectedService :
    DrillDownSelectList Cluster
    -> Service.Id
    -> DrillDownSelectList Cluster
setSelectedService clusters serviceId =
    DrillDownSelectList.nestedSelect
        clusters
        .services
        asServicesIn
        (Utils.sameId serviceId)


setSelectedCategory :
    DrillDownSelectList Cluster
    -> Category.Id
    -> DrillDownSelectList Cluster
setSelectedCategory clusters categoryId =
    let
        updateService =
            DrillDownSelectList.mapSelected
                (Service.setSelectedCategory categoryId)
    in
    DrillDownSelectList.updateNested
        clusters
        .services
        asServicesIn
        updateService


setSelectedIssue :
    DrillDownSelectList Cluster
    -> Issue.Id
    -> DrillDownSelectList Cluster
setSelectedIssue clusters issueId =
    let
        updateService =
            DrillDownSelectList.mapSelected (Service.setSelectedIssue issueId)
    in
    DrillDownSelectList.updateNested
        clusters
        .services
        asServicesIn
        updateService


setSelectedTier :
    DrillDownSelectList Cluster
    -> Tier.Id
    -> DrillDownSelectList Cluster
setSelectedTier clusters tierId =
    updateSelectedIssue clusters (Issue.selectTier tierId)


updateSelectedIssue :
    DrillDownSelectList Cluster
    -> (Issue -> Issue)
    -> DrillDownSelectList Cluster
updateSelectedIssue clusters changeIssue =
    let
        updateCluster =
            \cluster ->
                DrillDownSelectList.mapSelected updateService cluster.services
                    |> asServicesIn cluster

        updateService =
            \service ->
                updateIssues service.issues
                    |> Service.asIssuesIn service

        updateIssues =
            Issues.mapIssue changeIssue

        updateCategory =
            \category ->
                DrillDownSelectList.mapSelected changeIssue category.issues
                    |> Category.asIssuesIn category
    in
    DrillDownSelectList.mapSelected updateCluster clusters


setServices : DrillDownSelectList Service -> Cluster -> Cluster
setServices services cluster =
    { cluster | services = services }


asServicesIn : Cluster -> DrillDownSelectList Service -> Cluster
asServicesIn =
    flip setServices
