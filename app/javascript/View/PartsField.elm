module View.PartsField exposing (PartsFieldConfig(..), partsField)

import Cluster exposing (Cluster)
import ClusterPart exposing (ClusterPart)
import DrillDownSelectList exposing (DrillDownSelectList)
import Field exposing (Field)
import Html exposing (Html)
import SelectList exposing (Position(..), SelectList)
import State exposing (State)
import SupportType exposing (HasSupportType)
import View.Fields as Fields
import View.Utils


type
    PartsFieldConfig a
    -- XXX Could remove this and simplify now, the `NotRequired` case could
    -- just be handled directly and more simply in CaseForm?
    = SelectionField (Cluster -> DrillDownSelectList (ClusterPart a))
    | NotRequired


type alias PartsFromCluster a =
    Cluster -> SelectList (ClusterPart a)


partsField :
    Field
    -> PartsFieldConfig a
    -> (ClusterPart a -> Int)
    -> State
    -> (String -> msg)
    -> Html msg
partsField field partsFieldConfig toId state changeMsg =
    let
        labelForPart =
            \part ->
                case part.supportType of
                    SupportType.Advice ->
                        part.name ++ " (self-managed)"

                    _ ->
                        part.name

        selectField =
            \parts ->
                Fields.selectField
                    field
                    parts
                    toId
                    labelForPart
                    (always False)
                    changeMsg
                    state

        cluster =
            State.selectedCluster state
    in
    case partsFieldConfig of
        SelectionField partsForCluster ->
            let
                allParts =
                    partsForCluster cluster
            in
            -- Issue requires a part of this type => allow selection from all
            -- parts of this type for Cluster.
            selectField allParts

        NotRequired ->
            -- Issue does not require a part of this type => do not show any
            -- select.
            View.Utils.nothing
