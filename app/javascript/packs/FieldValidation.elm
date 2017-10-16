module FieldValidation exposing (..)


isInvalid : FieldValidation a -> Bool
isInvalid validation =
    case validation of
        Valid ->
            False

        Invalid _ ->
            True


error : a -> FieldValidation a -> String
error item validation =
    case validation of
        Valid ->
            ""

        Invalid errorForItem ->
            errorForItem item


validateWithEmptyError : (a -> Bool) -> a -> FieldValidation a
validateWithEmptyError =
    validateWithError ""


validateWithError : String -> (a -> Bool) -> a -> FieldValidation a
validateWithError error itemIsValid item =
    validateWithErrorForItem (always error) itemIsValid item


validateWithErrorForItem : (a -> String) -> (a -> Bool) -> a -> FieldValidation a
validateWithErrorForItem errorForItem itemIsValid item =
    if itemIsValid item then
        Valid
    else
        Invalid errorForItem


type FieldValidation a
    = Valid
    | Invalid (a -> String)
