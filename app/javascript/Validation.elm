module Validation
    exposing
        ( Error
        , ErrorMessage(..)
        , invalidState
        , unavailableTierErrorMessage
        , validateField
        , validateState
        )

import Dict
import DrillDownSelectList
import Field exposing (Field)
import Issue
import State exposing (State)
import Tier
import Tier.Field
import Validate exposing (Validator)


type alias Error =
    ( Field, ErrorMessage )


type ErrorMessage
    = Empty
    | Message String


invalidState : State -> Bool
invalidState state =
    not <| List.isEmpty <| validateState state


validateState : State -> List Error
validateState state =
    let
        validator =
            createStateValidator state
    in
    Validate.validate validator state


validateField : Field -> State -> List Error
validateField field state =
    let
        errorsForField =
            \errors ->
                List.filter
                    (Tuple.first >> (==) field)
                    errors
    in
    validateState state |> errorsForField


createStateValidator : State -> Validator Error State
createStateValidator state =
    Validate.all
        [ subjectPresentValidator

        -- We use a DrillDownSelectList for storing many items in the State,
        -- however Components are the only items that we store in this way and
        -- that are also displayed in an Unselected form at the point where it
        -- is possible to submit the Case form (since the Components field is
        -- shown, when required, when an Issue is Selected, and this also
        -- reveals all fields within the Tier tabs including the submit
        -- button).
        --
        -- Therefore we need to validate that a Component has been selected
        -- when required, to avoid the form being submitted without doing this;
        -- for other items stored as a DrillDownSelectList we do not need to do
        -- this since the form cannot be submitted without selecting them,
        -- however this may change if the form structure later changes.
        , componentSelectedIfRequiredValidator
        , createAvailableTierValidator state
        , createTierFieldsValidator state
        ]


subjectPresentValidator : Validator Error State
subjectPresentValidator =
    Validate.ifBlank
        (State.selectedIssue >> Issue.subject)
        ( Field.Subject, Empty )


componentSelectedIfRequiredValidator : Validator Error State
componentSelectedIfRequiredValidator =
    let
        componentRequiredAndNotSelected state =
            componentRequired state && not (componentSelected state)

        componentRequired =
            State.selectedIssue
                >> Issue.requiresComponent

        componentSelected =
            State.selectedCluster
                >> .components
                >> DrillDownSelectList.hasBeenSelected
    in
    Validate.ifTrue
        componentRequiredAndNotSelected
        ( Field.Component, Empty )


createAvailableTierValidator : State -> Validator Error State
createAvailableTierValidator state =
    Validate.ifTrue
        State.selectedTierSupportUnavailable
        ( Field.Tier, Message <| unavailableTierErrorMessage state )


unavailableTierErrorMessage : State -> String
unavailableTierErrorMessage state =
    "Logging tier 0-2 cases for a self-managed "
        ++ State.associatedModelTypeName state
        ++ " is not available."


createTierFieldsValidator : State -> Validator Error State
createTierFieldsValidator state =
    let
        tierFieldValidators =
            List.map createRequiredFieldValidator requiredTierFieldsTextInputData

        requiredTierFieldsTextInputData =
            State.selectedTier state
                |> Tier.fields
                |> Dict.values
                |> List.filterMap Tier.Field.data
                |> List.filter (not << .optional)

        createRequiredFieldValidator =
            \textInputData ->
                Validate.ifBlank
                    (always textInputData.value)
                    ( Field.TierField textInputData, Empty )
    in
    Validate.all tierFieldValidators
