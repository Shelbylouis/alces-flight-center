module State exposing (..)

import CaseCategory exposing (CaseCategory)
import Cluster exposing (Cluster)
import Component
import Issue exposing (Issue)
import Json.Decode as D
import Json.Encode as E
import SelectList exposing (SelectList)
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

        selectedCluster =
            SelectList.selected state.clusters

        selectedComponent =
            SelectList.selected selectedCluster.components

        componentIdValue =
            if issue.requiresComponent then
                Component.extractId selectedComponent |> E.int
            else
                E.null
    in
    E.object
        [ ( "case"
          , E.object
                [ ( "cluster_id", Cluster.extractId selectedCluster |> E.int )
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


isInvalid : State -> Bool
isInvalid state =
    let
        issue =
            selectedIssue state
    in
    List.any not
        [ Issue.detailsValid issue
        , Issue.availableForSelectedCluster state.clusters issue
        ]
