module View.PartsField exposing (partsField)

import Cluster exposing (Cluster)
import ClusterPart exposing (ClusterPart)
import DrillDownSelectList exposing (DrillDownSelectList)
import Field exposing (Field)
import Html exposing (Html)
import State exposing (State)
import SupportType exposing (HasSupportType)
import View.Fields as Fields


partsField :
    Field
    -> (Cluster -> DrillDownSelectList (ClusterPart a))
    -> (ClusterPart a -> Int)
    -> State
    -> (String -> msg)
    -> Html msg
partsField field partsForCluster toId state changeMsg =
    let
        labelForPart =
            \part ->
                case part.supportType of
                    SupportType.Advice ->
                        part.name ++ " (self-managed)"

                    _ ->
                        part.name

        cluster =
            State.selectedCluster state
    in
    Fields.selectField
        field
        (partsForCluster cluster)
        toId
        labelForPart
        (always False)
        changeMsg
        state
