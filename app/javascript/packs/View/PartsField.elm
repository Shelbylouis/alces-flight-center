module View.PartsField exposing (PartsFieldConfig(..), maybePartsField)

import Cluster exposing (Cluster)
import ClusterPart exposing (ClusterPart)
import Html exposing (Html)
import SelectList exposing (Position(..), SelectList)
import State exposing (State)
import SupportType exposing (HasSupportType)
import Validation
import View.Fields as Fields


type PartsFieldConfig a
    = SelectionField (PartsFromCluster a)
    | SinglePartField (ClusterPart a)
    | NotRequired


type alias PartsFromCluster a =
    Cluster -> SelectList (ClusterPart a)


maybePartsField :
    Validation.Field
    -> PartsFieldConfig a
    -> (ClusterPart a -> Int)
    -> State
    -> (String -> msg)
    -> Maybe (Html msg)
maybePartsField field partsFieldConfig toId state changeMsg =
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
                    changeMsg
                    state
                    |> Just

        cluster =
            SelectList.selected state.clusters
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

        SinglePartField part ->
            -- We're creating a Case for a specific part => don't want to allow
            -- selection of another part, but do still want to display any
            -- error between this part and selected Issue.
            -- XXX Do nothing for this case for now (there are currently no
            -- part validations in any case); add something appropriate back
            -- once Tiers implemented.
            Nothing

        NotRequired ->
            -- Issue does not require a part of this type => do not show any
            -- select.
            Nothing


errorForClusterPart : String -> HasSupportType a -> String
errorForClusterPart partName part =
    if SupportType.isManaged part then
        "This " ++ partName ++ " is already fully managed."
    else
        "This "
            ++ partName
            ++ """ is self-managed; if required you may only request
            consultancy support from Alces Software."""
