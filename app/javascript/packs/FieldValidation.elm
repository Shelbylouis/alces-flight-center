module FieldValidation exposing (..)


isInvalid : FieldValidation -> Bool
isInvalid validation =
    case validation of
        Valid ->
            False

        Invalid _ ->
            True


error : FieldValidation -> String
error validation =
    case validation of
        Valid ->
            ""

        Invalid message ->
            message


validateWithEmptyError : (a -> Bool) -> a -> FieldValidation
validateWithEmptyError =
    validateWithError ""


validateWithError : String -> (a -> Bool) -> a -> FieldValidation
validateWithError error itemIsValid item =
    if itemIsValid item then
        Valid
    else
        Invalid error


type FieldValidation
    = Valid
    | Invalid String
