module State exposing (..)

import CaseCategory exposing (CaseCategory)
import Cluster exposing (Cluster)
import ClusterPart exposing (ClusterPart)
import Component exposing (Component)
import Issue exposing (Issue)
import Json.Decode as D
import Json.Encode as E
import SelectList exposing (SelectList)
import SupportType exposing (SupportType(..))
import Utils


type alias State =
    { clusters : SelectList Cluster
    , caseCategories : SelectList CaseCategory
    , error : Maybe String
    , singleComponent : Bool
    , isSubmitting : Bool
    }


decoder : D.Decoder State
decoder =
    let
        createInitialState =
            \( clusters, caseCategories, singleComponentId ) ->
                -- XXX Change state structure/how things are passed in to Elm
                -- app to make invalid states in 'single component mode'
                -- impossible?
                case singleComponentId of
                    Just id ->
                        let
                            singleClusterWithSingleComponentSelected =
                                Cluster.setSelectedComponent clusters (Component.Id id)

                            applicableCaseCategoriesAndIssues =
                                -- Only include CaseCategorys, and Issues
                                -- within them, which require a Component.
                                SelectList.toList caseCategories
                                    |> List.filter CaseCategory.hasAnyIssueRequiringComponent
                                    |> Utils.selectListFromList
                        in
                        case applicableCaseCategoriesAndIssues of
                            Just caseCategories ->
                                D.succeed
                                    { clusters = singleClusterWithSingleComponentSelected
                                    , caseCategories = caseCategories
                                    , error = Nothing
                                    , singleComponent = True
                                    , isSubmitting = False
                                    }

                            Nothing ->
                                D.fail "expected some Issues to exist requiring a Component, but none were found"

                    Nothing ->
                        D.succeed
                            { clusters = clusters
                            , caseCategories = caseCategories
                            , error = Nothing
                            , singleComponent = False
                            , isSubmitting = False
                            }
    in
    D.map3
        (\a -> \b -> \c -> ( a, b, c ))
        (D.field "clusters" <| Utils.selectListDecoder Cluster.decoder)
        (D.field "caseCategories" <| Utils.selectListDecoder CaseCategory.decoder)
        (D.field "singleComponentId" <| D.nullable D.int)
        |> D.andThen createInitialState


encoder : State -> E.Value
encoder state =
    let
        issue =
            selectedIssue state

        cluster =
            SelectList.selected state.clusters

        componentIdValue =
            if issue.requiresComponent then
                selectedComponent state
                    |> Component.extractId
                    |> E.int
            else
                E.null
    in
    E.object
        [ ( "case"
          , E.object
                [ ( "cluster_id", Cluster.extractId cluster |> E.int )
                , ( "issue_id", Issue.extractId issue |> E.int )
                , ( "component_id", componentIdValue )
                , ( "details", E.string issue.details )
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


clusterPartAllowedForSelectedIssue : State -> (Issue -> Bool) -> ClusterPart a -> Bool
clusterPartAllowedForSelectedIssue state issueRequiresPart part =
    let
        issue =
            selectedIssue state
    in
    if issueRequiresPart issue then
        case ( issue.supportType, part.supportType ) of
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
    in
    List.any not
        [ Issue.detailsValid issue
        , Issue.availableForSelectedCluster state.clusters issue
        , partAllowedForSelectedIssue .requiresComponent component
        ]
