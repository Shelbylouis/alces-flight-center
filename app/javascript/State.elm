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
        , selectedTier
        , selectedTierSupportUnavailable
        )

import Bootstrap.Modal as Modal
import Cluster exposing (Cluster)
import Component exposing (Component)
import DrillDownSelectList exposing (DrillDownSelectList)
import Issue exposing (Issue)
import Issues
import Json.Decode as D
import Json.Encode as E
import SelectList exposing (SelectList)
import SelectList.Extra
import Service exposing (Service)
import SupportType exposing (SupportType)
import Tier exposing (Tier)
import Tier.Level


type alias State =
    { clusters : DrillDownSelectList Cluster
    , error : Maybe String
    , singleComponent : Bool
    , singleService : Bool
    , isSubmitting : Bool
    , clusterChargingInfoModal : Modal.Visibility
    , chargeablePreSubmissionModal : Modal.Visibility
    }


decoder : D.Decoder State
decoder =
    let
        createInitialState =
            \( clusters, mode ) ->
                let
                    initialState =
                        { clusters = clusters
                        , error = Nothing
                        , singleComponent = False
                        , singleService = False
                        , isSubmitting = False
                        , clusterChargingInfoModal = Modal.hidden
                        , chargeablePreSubmissionModal = Modal.hidden
                        }
                in
                case mode of
                    SingleComponentMode id ->
                        let
                            singleClusterWithSingleComponentSelected =
                                Cluster.setSelectedComponent clusters id

                            applicableServices =
                                -- Only include Services, and Issues within
                                -- them, which require a Component.
                                DrillDownSelectList.selected singleClusterWithSingleComponentSelected
                                    |> .services
                                    |> Service.filterByIssues Issue.requiresComponent
                        in
                        case applicableServices of
                            Just services ->
                                let
                                    newClusters =
                                        -- Set just the applicable Services in
                                        -- the single Cluster SelectList.
                                        DrillDownSelectList.selected singleClusterWithSingleComponentSelected
                                            |> Cluster.setServices services
                                            |> SelectList.singleton
                                            |> DrillDownSelectList.Unselected
                                in
                                D.succeed
                                    { initialState
                                        | clusters = newClusters
                                        , singleComponent = True
                                    }

                            Nothing ->
                                D.fail "expected some Issues to exist requiring a Component, but none were found"

                    SingleServiceMode id ->
                        let
                            singleClusterWithSingleServiceSelected =
                                Cluster.setSelectedService clusters id

                            partialNewState =
                                { initialState
                                    | clusters = singleClusterWithSingleServiceSelected
                                    , singleService = True
                                }

                            singleService =
                                selectedService partialNewState
                        in
                        D.succeed partialNewState

                    ClusterMode ->
                        D.succeed initialState

        setClustersSelectedIfSingleClusterAvailable state =
            let
                singleClusterAvailable =
                    DrillDownSelectList.toList state.clusters
                        |> List.length
                        |> (==) 1
            in
            if singleClusterAvailable then
                { state
                    | clusters =
                        DrillDownSelectList.unwrap state.clusters
                            |> DrillDownSelectList.Selected
                }
            else
                state
    in
    D.map2
        (,)
        (D.field "clusters" <|
            D.map DrillDownSelectList.Unselected <|
                SelectList.Extra.nameOrderedDecoder Cluster.decoder
        )
        (D.field "singlePart" <| modeDecoder)
        |> D.andThen
            (createInitialState
                -- If only a single Cluster is available we hide the Cluster
                -- selection field as no need to show it, but want to otherwise
                -- seamlessly handle things as if the user had selected a
                -- Cluster; therefore in this case pre-select the Clusters in
                -- the same way as if a user had selected one.
                >> D.map setClustersSelectedIfSingleClusterAvailable
            )


type Mode
    = ClusterMode
    | SingleComponentMode Component.Id
    | SingleServiceMode Service.Id


type alias SinglePartModeFields =
    { id : Int
    , type_ : String
    }


modeDecoder : D.Decoder Mode
modeDecoder =
    let
        singlePartModeFieldsDecoder =
            D.map2 SinglePartModeFields
                (D.field "id" D.int)
                (D.field "type" D.string)

        fieldsToMode =
            Maybe.map singlePartModeDecoder
                >> Maybe.withDefault (D.succeed ClusterMode)
    in
    D.nullable singlePartModeFieldsDecoder |> D.andThen fieldsToMode


singlePartModeDecoder : SinglePartModeFields -> D.Decoder Mode
singlePartModeDecoder fields =
    case fields.type_ of
        "component" ->
            Component.Id fields.id |> SingleComponentMode |> D.succeed

        "service" ->
            Service.Id fields.id |> SingleServiceMode |> D.succeed

        _ ->
            "Unknown type: " ++ fields.type_ |> D.fail


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
    selectedService state |> .issues |> Issues.availableIssues


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
