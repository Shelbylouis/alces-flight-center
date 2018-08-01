module Field
    exposing
        ( Field(..)
        , hasBeenTouched
        , isDynamicField
        , parentFieldHasBeenSelected
        )

import DrillDownSelectList
import Issues exposing (Issues(..))
import State exposing (State)
import Tier.Field


type Field
    = Cluster
    | Service
    | Category
    | Issue
    | Tier
    | Component
    | Subject
    | TierField Tier.Field.TextInputData


{-| The 'dynamic' fields are those shown in the lower section of the form,
whose value and/or presence frequently changes based on the selected Issue and
Tier.
-}
isDynamicField : Field -> Bool
isDynamicField field =
    case field of
        Subject ->
            True

        TierField _ ->
            True

        _ ->
            False


hasBeenTouched : Field -> Bool
hasBeenTouched field =
    case field of
        TierField data ->
            -- A Tier field has been touched if we have saved that we have
            -- touched it.
            case data.touched of
                Tier.Field.Touched ->
                    True

                Tier.Field.Untouched ->
                    False

        _ ->
            -- Always consider every other field touched, since they all start
            -- pre-filled.
            True


parentFieldHasBeenSelected : State -> Field -> Bool
parentFieldHasBeenSelected state field =
    case field of
        Cluster ->
            True

        Service ->
            clusterSelected state

        Component ->
            -- Whether a Component is required is dependent on whether the
            -- current Issue requires a Component, so the user must also have
            -- first selected an Issue before we decide whether to display this
            -- field.
            issueSelected state

        Category ->
            case State.selectedServiceIssues state of
                CategorisedIssues categories ->
                    serviceSelected state

                JustIssues _ ->
                    False

        Issue ->
            case State.selectedServiceIssues state of
                CategorisedIssues categories ->
                    categorySelected state

                JustIssues _ ->
                    serviceSelected state

        Tier ->
            issueSelected state

        Subject ->
            issueSelected state

        TierField _ ->
            issueSelected state


clusterSelected : State -> Bool
clusterSelected state =
    DrillDownSelectList.hasBeenSelected state.clusters


serviceSelected : State -> Bool
serviceSelected state =
    State.selectedCluster state
        |> .services
        |> DrillDownSelectList.hasBeenSelected


categorySelected : State -> Bool
categorySelected state =
    State.selectedService state
        |> .issues
        |> (\issues ->
                case issues of
                    JustIssues _ ->
                        False

                    CategorisedIssues categories ->
                        DrillDownSelectList.hasBeenSelected categories
           )


issueSelected : State -> Bool
issueSelected state =
    State.selectedServiceIssues state
        |> Issues.availableIssues
        |> DrillDownSelectList.hasBeenSelected
