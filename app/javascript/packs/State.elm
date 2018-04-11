module State
    exposing
        ( State
        , decoder
        , encoder
        , selectedComponent
        , selectedIssue
        , selectedService
        , selectedServiceAvailableIssues
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
            \required ->
                \selected ->
                    \extractId ->
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
    in
    E.object
        [ ( "case"
          , E.object
                [ ( "cluster_id", Cluster.extractId cluster |> E.int )
                , ( "issue_id", Issue.extractId issue |> E.int )
                , ( "component_id", componentIdValue )
                , ( "service_id", serviceIdValue )
                , ( "subject", Issue.subject issue |> E.string )
                , ( "details", Issue.details issue |> E.string )
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


selectedServiceAvailableIssues : State -> SelectList Issue
selectedServiceAvailableIssues state =
    selectedService state |> .issues |> Issues.availableIssues
