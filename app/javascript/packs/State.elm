module State exposing (..)

import CaseCategory exposing (CaseCategory)
import Cluster exposing (Cluster)
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
    in
    if issue.requiresComponent then
        case ( issue.supportType, component.supportType ) of
            ( Managed, Advice ) ->
                -- An advice Component cannot be associated with a managed
                -- issue.
                False

            ( AdviceOnly, Managed ) ->
                -- A managed Component cannot be associated with an advice-only
                -- issue.
                False

            _ ->
                -- Everything else is valid.
                True
    else
        -- This validation should always pass if component is not required.
        True


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
