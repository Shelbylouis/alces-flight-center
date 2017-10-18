module State exposing (..)

import CaseCategory exposing (CaseCategory)
import Cluster exposing (Cluster)
import Component exposing (Component)
import Issue exposing (Issue)
import Json.Decode as D
import Json.Encode as E
import SelectList exposing (SelectList)
import SupportType
import Utils


type alias State =
    { clusters : SelectList Cluster
    , caseCategories : SelectList CaseCategory
    , error : Maybe String
    , isSubmitting : Bool
    }


decoder : D.Decoder State
decoder =
    let
        createInitialState =
            \clusters ->
                \caseCategories ->
                    { clusters = clusters
                    , caseCategories = caseCategories
                    , error = Nothing
                    , isSubmitting = False
                    }
    in
    D.map2 createInitialState
        (D.field "clusters" <| Utils.selectListDecoder Cluster.decoder)
        (D.field "caseCategories" <| Utils.selectListDecoder CaseCategory.decoder)


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


componentAllowedForSelectedIssue : State -> Component -> Bool
componentAllowedForSelectedIssue state component =
    let
        issue =
            selectedIssue state

        issueIsManaged =
            SupportType.isManaged issue

        componentIsAdvice =
            SupportType.isAdvice component
    in
    -- A Component is allowed unless the selected Issue is a managed Issue, it
    -- requires a Component, and the selected Component is advice-only.
    not (issueIsManaged && issue.requiresComponent && componentIsAdvice)


isInvalid : State -> Bool
isInvalid state =
    let
        issue =
            selectedIssue state

        component =
            selectedComponent state
    in
    List.any not
        [ Issue.detailsValid issue
        , Issue.availableForSelectedCluster state.clusters issue
        , componentAllowedForSelectedIssue state component
        ]
