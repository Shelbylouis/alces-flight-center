module Validation
    exposing
        ( Error
        , ErrorMessage(..)
        , invalidState
        , unavailableTierErrorMessage
        , validateField
        , validateState
        )

import Field exposing (Field)
import Issue
import State exposing (State)
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
        , createAvailableTierValidator state

        -- XXX Not handling any other validations for now, as these are
        -- currently either very improbable or impossible to trigger (at least
        -- with the current production data and how we initialize the Case form
        -- app) and will significantly change anyway once we handle Tiers.
        ]


subjectPresentValidator : Validator Error State
subjectPresentValidator =
    Validate.ifBlank
        (State.selectedIssue >> Issue.subject)
        ( Field.Subject, Empty )


createAvailableTierValidator : State -> Validator Error State
createAvailableTierValidator state =
    Validate.ifTrue
        State.selectedTierSupportUnavailable
        ( Field.Tier, Message <| unavailableTierErrorMessage state )


unavailableTierErrorMessage : State -> String
unavailableTierErrorMessage state =
    "Selected "
        ++ State.associatedModelTypeName state
        ++ """ is self-managed; if required you may only request consultancy
        support from Alces Software."""
