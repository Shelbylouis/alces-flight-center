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
    Validate.validate stateValidator state


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


stateValidator : Validator Error State
stateValidator =
    Validate.all
        [ Validate.ifBlank (State.selectedIssue >> Issue.subject) ( Field.Subject, Empty )

        -- XXX Display error message for this error.
        , Validate.ifFalse State.canRequestSupportForSelectedTier ( Field.Tier, Empty )

        -- XXX Not handling any other validations for now, as these are
        -- currently either very improbable or impossible to trigger (at least
        -- with the current production data and how we initialize the Case form
        -- app) and will significantly change anyway once we handle Tiers.
        ]
