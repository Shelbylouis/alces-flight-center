module State
    exposing
        ( State
        , canRequestSupportForSelectedTier
        , decoder
        , encoder
        , selectedComponent
        , selectedIssue
        , selectedService
        , selectedServiceAvailableIssues
        , selectedTier
        )

import Bootstrap.Modal as Modal
import Cluster exposing (Cluster)
import Component exposing (Component)
import Issue exposing (Issue)
import Issues
import Json.Decode as D
import Json.Encode as E
import SelectList exposing (SelectList)
import SelectList.Extra
import Service exposing (Service)
import SupportType exposing (SupportType)
import Tier exposing (Tier)


type alias State =
    { clusters : SelectList Cluster
    , error : Maybe String
    , singleComponent : Bool
    , singleService : Bool
    , isSubmitting : Bool
    , clusterChargingInfoModal : Modal.State
    , chargeableIssuePreSubmissionModal : Modal.State
    }


decoder : D.Decoder State
decoder =
    let
        createInitialState =
            \( clusters, mode ) ->
                -- XXX Change state structure/how things are passed in to Elm
                -- app to make invalid states in 'single component mode'
                -- impossible?
                let
                    initialState =
                        { clusters = clusters
                        , error = Nothing
                        , singleComponent = False
                        , singleService = False
                        , isSubmitting = False
                        , clusterChargingInfoModal = Modal.hiddenState
                        , chargeableIssuePreSubmissionModal = Modal.hiddenState
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
                                SelectList.selected singleClusterWithSingleComponentSelected
                                    |> .services
                                    |> Service.filterByIssues Issue.requiresComponent
                        in
                        case applicableServices of
                            Just services ->
                                let
                                    newClusters =
                                        -- Set just the applicable Services in
                                        -- the single Cluster SelectList.
                                        SelectList.selected singleClusterWithSingleComponentSelected
                                            |> Cluster.setServices services
                                            |> SelectList.singleton
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
    in
    D.map2
        (,)
        (D.field "clusters" <| SelectList.Extra.nameOrderedDecoder Cluster.decoder)
        (D.field "singlePart" <| modeDecoder)
        |> D.andThen createInitialState


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
            SelectList.selected state.clusters

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

        tierFieldAsString =
            \field ->
                case field of
                    Tier.Markdown _ ->
                        Nothing

                    Tier.TextInput data ->
                        Just <| data.name ++ ": " ++ data.value
    in
    E.object
        [ ( "case"
          , E.object
                [ ( "cluster_id", Cluster.extractId cluster |> E.int )
                , ( "issue_id", Issue.extractId issue |> E.int )
                , ( "component_id", componentIdValue )
                , ( "service_id", serviceIdValue )
                , ( "subject", Issue.subject issue |> E.string )
                , ( "tier_level", Tier.levelAsInt tier |> E.int )
                , ( "fields", Tier.fieldsEncoder tier )
                ]
          )
        ]


selectedIssue : State -> Issue
selectedIssue state =
    selectedService state
        |> .issues
        |> Issues.selectedIssue


selectedComponent : State -> Component
selectedComponent state =
    SelectList.selected state.clusters
        |> .components
        |> SelectList.selected


selectedService : State -> Service
selectedService state =
    SelectList.selected state.clusters
        |> .services
        |> SelectList.selected


selectedTier : State -> Tier
selectedTier state =
    selectedIssue state
        |> Issue.tiers
        |> SelectList.selected


selectedServiceAvailableIssues : State -> SelectList Issue
selectedServiceAvailableIssues state =
    selectedService state |> .issues |> Issues.availableIssues


canRequestSupportForSelectedTier : State -> Bool
canRequestSupportForSelectedTier state =
    let
        tier =
            selectedTier state
    in
    case tier.level of
        Tier.Three ->
            -- Can always request Tier 3 support.
            True

        _ ->
            case associatedModelSupportType state of
                SupportType.Managed ->
                    -- Can request any Tier support for managed
                    -- Components/Services.
                    True

                SupportType.Advice ->
                    -- Cannot request any other Tier support for advice-only
                    -- Components/Services.
                    False


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
