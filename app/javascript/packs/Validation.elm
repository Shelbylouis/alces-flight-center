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
import Field exposing (Field)
import Issue
import State exposing (State)
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
        , createAvailableTierValidator state
        , createTierFieldsValidator state
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
        ++ " is self-managed; if required you may only request consultancy"
        ++ " support from Alces Software."


createTierFieldsValidator : State -> Validator Error State
createTierFieldsValidator state =
    let
        tierFieldValidators =
            List.map createTierFieldValidator tierFieldsTextInputData

        tierFieldsTextInputData =
            State.selectedTier state
                |> .fields
                |> Dict.values
                |> List.filterMap
                    (\field ->
                        case field of
                            Tier.Field.Markdown _ ->
                                Nothing

                            Tier.Field.TextInput data ->
                                Just data
                    )

        createTierFieldValidator =
            \textInputData ->
                Validate.ifBlank
                    (always textInputData.value)
                    ( Field.TierField textInputData, Empty )
    in
    Validate.all tierFieldValidators
