module State
    exposing
        ( State
        , clusterPartAllowedForSelectedIssue
        , decoder
        , encoder
        , isInvalid
        , selectedComponent
        , selectedIssue
        , selectedService
        )

import CaseCategory exposing (CaseCategory)
import Cluster exposing (Cluster)
import ClusterPart exposing (ClusterPart)
import Component exposing (Component)
import Issue exposing (Issue)
import Json.Decode as D
import Json.Encode as E
import SelectList exposing (SelectList)
import SelectList.Extra
import Service exposing (Service)
import SupportType exposing (SupportType(..))
import Utils


type alias State =
    { clusters : SelectList Cluster
    , caseCategories : SelectList CaseCategory
    , error : Maybe String
    , singleComponent : Bool
    , singleService : Bool
    , isSubmitting : Bool
    , showingClusterChargingInfo : Bool
    }


decoder : D.Decoder State
decoder =
    let
        createInitialState =
            \( clusters, caseCategories, mode ) ->
                -- XXX Change state structure/how things are passed in to Elm
                -- app to make invalid states in 'single component mode'
                -- impossible?
                let
                    initialState =
                        { clusters = clusters
                        , caseCategories = caseCategories
                        , error = Nothing
                        , singleComponent = False
                        , singleService = False
                        , isSubmitting = False
                        , showingClusterChargingInfo = False
                        }
                in
                case mode of
                    SingleComponentMode id ->
                        let
                            singleClusterWithSingleComponentSelected =
                                Cluster.setSelectedComponent clusters id

                            applicableCaseCategories =
                                -- Only include CaseCategorys, and Issues
                                -- within them, which require a Component.
                                CaseCategory.filterByIssues caseCategories Issue.requiresComponent
                        in
                        case applicableCaseCategories of
                            Just caseCategories ->
                                D.succeed
                                    { initialState
                                        | clusters = singleClusterWithSingleComponentSelected
                                        , caseCategories = caseCategories
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

                            caseCategoriesControlledByService =
                                -- Want to show CaseCategorys, and all Issues
                                -- within them, which are controlled by the
                                -- current Service.
                                SelectList.toList caseCategories
                                    |> List.filter (CaseCategory.isControlledByService singleService)

                            otherCaseCategoriesWithIssuesTakingThisService =
                                -- Also want to show other Issues, and parent
                                -- CaseCategorys, which require a Service and
                                -- this Service is acceptable for.
                                CaseCategory.filterByIssues
                                    caseCategories
                                    (Issue.serviceCanBeAssociatedWith singleService)
                                    |> Maybe.map
                                        (SelectList.toList
                                            -- Filter out the CaseCategorys
                                            -- which will already be included
                                            -- in the final list by
                                            -- `caseCategoriesControlledByService`.
                                            >> List.filter
                                                (\caseCategory ->
                                                    List.any
                                                        (Utils.sameId caseCategory.id)
                                                        caseCategoriesControlledByService
                                                        |> not
                                                )
                                        )
                                    |> Maybe.withDefault []

                            availableCaseCategories =
                                caseCategoriesControlledByService
                                    ++ otherCaseCategoriesWithIssuesTakingThisService
                                    |> SelectList.Extra.fromList
                        in
                        case availableCaseCategories of
                            Just caseCategories ->
                                D.succeed
                                    { partialNewState
                                        | caseCategories = caseCategories
                                    }

                            Nothing ->
                                D.fail "expected some Issues to exist requiring a Service, but none were found"

                    ClusterMode ->
                        D.succeed initialState
    in
    D.map3
        (\a -> \b -> \c -> ( a, b, c ))
        (D.field "clusters" <| SelectList.Extra.decoder Cluster.decoder)
        (D.field "caseCategories" <| SelectList.Extra.decoder CaseCategory.decoder)
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
            partIdValue
                Issue.requiresService
                selectedService
                Service.extractId
    in
    E.object
        [ ( "case"
          , E.object
                [ ( "cluster_id", Cluster.extractId cluster |> E.int )
                , ( "issue_id", Issue.extractId issue |> E.int )
                , ( "component_id", componentIdValue )
                , ( "service_id", serviceIdValue )
                , ( "details", Issue.details issue |> E.string )
                ]
          )
        ]


selectedIssue : State -> Issue
selectedIssue state =
    SelectList.selected state.caseCategories
        |> .issues
        |> SelectList.selected


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


clusterPartAllowedForSelectedIssue : State -> (Issue -> Bool) -> ClusterPart a -> Bool
clusterPartAllowedForSelectedIssue state issueRequiresPart part =
    let
        issue =
            selectedIssue state
    in
    if issueRequiresPart issue then
        case ( Issue.supportType issue, part.supportType ) of
            ( Managed, Advice ) ->
                -- An advice part cannot be associated with a managed issue.
                False

            ( AdviceOnly, Managed ) ->
                -- A managed part cannot be associated with an advice-only
                -- issue.
                False

            _ ->
                -- Everything else is valid.
                True
    else
        -- This validation should always pass if part is not required.
        True


isInvalid : State -> Bool
isInvalid state =
    let
        issue =
            selectedIssue state

        partAllowedForSelectedIssue =
            clusterPartAllowedForSelectedIssue state

        component =
            selectedComponent state

        service =
            selectedService state
    in
    List.any not
        [ Issue.detailsValid issue
        , Issue.availableForSelectedCluster state.clusters issue
        , partAllowedForSelectedIssue Issue.requiresComponent component
        , partAllowedForSelectedIssue Issue.requiresService service
        , Issue.serviceAllowedFor issue service
        ]
