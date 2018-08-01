module State
    exposing
        ( State
        , associatedModelTypeName
        , decoder
        , encoder
        , selectedCluster
        , selectedComponent
        , selectedIssue
        , selectedService
        , selectedServiceAvailableIssues
        , selectedServiceIssues
        , selectedTier
        , selectedTierSupportUnavailable
        , singleClusterAvailable
        )

import Bootstrap.Modal as Modal
import Cluster exposing (Cluster)
import Component exposing (Component)
import DrillDownSelectList exposing (DrillDownSelectList)
import Issue exposing (Issue)
import Issues exposing (Issues)
import Json.Decode as D
import Json.Encode as E
import SelectList exposing (SelectList)
import Service exposing (Service)
import SupportType exposing (SupportType)
import Tier exposing (Tier)
import Tier.Level


type alias State =
    { clusters : DrillDownSelectList Cluster
    , error : Maybe String
    , isSubmitting : Bool
    , clusterChargingInfoModal : Modal.Visibility
    , chargeablePreSubmissionModal : Modal.Visibility
    }


decoder : D.Decoder State
decoder =
    let
        createInitialState clusters =
            D.succeed
                { clusters = clusters
                , error = Nothing
                , isSubmitting = False
                , clusterChargingInfoModal = Modal.hidden
                , chargeablePreSubmissionModal = Modal.hidden
                }

        setClustersSelectedIfSingleClusterAvailable state =
            if singleClusterAvailable state then
                { state
                    | clusters =
                        DrillDownSelectList.unwrap state.clusters
                            |> DrillDownSelectList.Selected
                }
            else
                state
    in
    (D.field "clusters" <|
        DrillDownSelectList.nameOrderedDecoder Cluster.decoder
    )
        |> D.andThen
            (createInitialState
                -- If only a single Cluster is available we hide the Cluster
                -- selection field as no need to show it, but want to otherwise
                -- seamlessly handle things as if the user had selected a
                -- Cluster; therefore in this case pre-select the Clusters in
                -- the same way as if a user had selected one.
                >> D.map setClustersSelectedIfSingleClusterAvailable
            )


encoder : State -> E.Value
encoder state =
    let
        issue =
            selectedIssue state

        cluster =
            selectedCluster state

        partIdValue =
            \required selected extractId ->
                if required issue then
                    selected state |> extractId |> E.int
                else
                    E.null

        componentIdValue =
            partIdValue
                Issue.requiresComponent
                selectedComponent
                Component.extractId

        serviceIdValue =
            selectedService state
                |> Service.extractId
                |> E.int

        tier =
            selectedTier state
    in
    E.object
        [ ( "case"
          , E.object
                [ ( "cluster_id", Cluster.extractId cluster |> E.int )
                , ( "issue_id", Issue.extractId issue |> E.int )
                , ( "component_id", componentIdValue )
                , ( "service_id", serviceIdValue )
                , ( "subject", Issue.subject issue |> E.string )
                , ( "tier_level", Tier.Level.asInt tier.level |> E.int )
                , Tier.encodeContentPair tier
                ]
          )
        ]


selectedIssue : State -> Issue
selectedIssue state =
    selectedService state
        |> .issues
        |> Issues.selectedIssue


selectedCluster : State -> Cluster
selectedCluster state =
    DrillDownSelectList.selected state.clusters


selectedComponent : State -> Component
selectedComponent state =
    selectedCluster state
        |> .components
        |> DrillDownSelectList.selected


selectedService : State -> Service
selectedService state =
    selectedCluster state
        |> .services
        |> DrillDownSelectList.selected


selectedTier : State -> Tier
selectedTier state =
    selectedIssue state
        |> Issue.tiers
        |> SelectList.selected


selectedServiceAvailableIssues : State -> DrillDownSelectList Issue
selectedServiceAvailableIssues state =
    selectedServiceIssues state |> Issues.availableIssues


selectedServiceIssues : State -> Issues
selectedServiceIssues state =
    selectedService state |> .issues


selectedTierSupportUnavailable : State -> Bool
selectedTierSupportUnavailable state =
    let
        tier =
            selectedTier state
    in
    case tier.level of
        Tier.Level.Three ->
            -- Can always request Tier 3 support.
            False

        _ ->
            case associatedModelSupportType state of
                SupportType.Managed ->
                    -- Can request any Tier support for managed
                    -- Components/Services.
                    False

                SupportType.Advice ->
                    -- Cannot request any other Tier support for advice-only
                    -- Components/Services.
                    True


{-| Returns the SupportType for the currently selected 'associated model'.

The associated model is the model which would be most closely associated with
the current Case if it was created, i.e. the selected Component if the selected
Issue requires one, or the selected Service if not.

-}
associatedModelSupportType : State -> SupportType
associatedModelSupportType state =
    if selectedIssue state |> Issue.requiresComponent then
        selectedComponent state |> .supportType
    else
        selectedService state |> .supportType


associatedModelTypeName : State -> String
associatedModelTypeName state =
    if selectedIssue state |> Issue.requiresComponent then
        "component"
    else
        "service"


singleClusterAvailable : State -> Bool
singleClusterAvailable =
    .clusters
        >> DrillDownSelectList.toList
        >> List.length
        >> (==) 1
