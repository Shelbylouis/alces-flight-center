module Validation
    exposing
        ( Error
        , ErrorMessage(..)
        , invalidState
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
    let
        tierErrorMessage =
            "Selected "
                ++ State.associatedModelTypeName state
                ++ """ is self-managed; if required you may only request
            consultancy support from Alces Software."""
    in
    Validate.all
        [ Validate.ifBlank (State.selectedIssue >> Issue.subject) ( Field.Subject, Empty )
        , Validate.ifFalse State.canRequestSupportForSelectedTier ( Field.Tier, Message tierErrorMessage )

        -- XXX Not handling any other validations for now, as these are
        -- currently either very improbable or impossible to trigger (at least
        -- with the current production data and how we initialize the Case form
        -- app) and will significantly change anyway once we handle Tiers.
        ]
