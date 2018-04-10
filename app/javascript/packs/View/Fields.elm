module View.Fields
    exposing
        ( hiddenInputWithVisibleError
        , inputField
        , selectField
        , textareaField
        )

import FieldValidation exposing (FieldValidation(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Json.Decode as D
import SelectList exposing (Position(..), SelectList)
import String.Extra
import Validation


selectField :
    Validation.Field
    -> SelectList a
    -> (a -> Int)
    -> (a -> String)
    -> (a -> FieldValidation a)
    -> (String -> msg)
    -> Html msg
selectField field items toId toOptionLabel validate changeMsg =
    let
        validatedField =
            SelectList.selected items |> validate

        fieldOption =
            \position ->
                \item ->
                    option
                        [ toId item |> toString |> value
                        , position == Selected |> selected
                        , validate item |> FieldValidation.isInvalid |> disabled
                        ]
                        [ toOptionLabel item |> text ]

        options =
            SelectList.mapBy fieldOption items
                |> SelectList.toList
    in
    formField field
        (SelectList.selected items)
        validatedField
        select
        [ Html.Events.on "change" (D.map changeMsg Html.Events.targetValue) ]
        options


textareaField :
    Validation.Field
    -> a
    -> (a -> String)
    -> (a -> FieldValidation a)
    -> (String -> msg)
    -> Html msg
textareaField =
    textField TextArea


inputField :
    Validation.Field
    -> a
    -> (a -> String)
    -> (a -> FieldValidation a)
    -> (String -> msg)
    -> Html msg
inputField =
    textField Input


type TextField
    = Input
    | TextArea


textField :
    TextField
    -> Validation.Field
    -> a
    -> (a -> String)
    -> (a -> FieldValidation a)
    -> (String -> msg)
    -> Html msg
textField textFieldType field item toContent validate inputMsg =
    let
        validatedField =
            validate item

        content =
            toContent item

        ( element, additionalAttributes ) =
            case textFieldType of
                Input ->
                    ( input, [] )

                TextArea ->
                    ( textarea, [ rows 10 ] )

        attributes =
            [ onInput inputMsg
            , value content
            ]
                ++ additionalAttributes
    in
    formField field
        item
        validatedField
        element
        attributes
        []


type alias HtmlFunction msg =
    List (Attribute msg) -> List (Html msg) -> Html msg


formField :
    Validation.Field
    -> a
    -> FieldValidation a
    -> HtmlFunction msg
    -> List (Attribute msg)
    -> List (Html msg)
    -> Html msg
formField field item validation htmlFn additionalAttributes children =
    let
        fieldName =
            toString field

        identifier =
            fieldIdentifier fieldName

        attributes =
            List.append
                [ id identifier
                , class (formControlClasses validation)
                ]
                additionalAttributes

        formElement =
            htmlFn attributes children
    in
    div [ class "form-group" ]
        [ label
            [ for identifier ]
            [ text fieldName ]
        , formElement
        , validationFeedback item validation
        ]


hiddenInputWithVisibleError : a -> (a -> FieldValidation a) -> Html msg
hiddenInputWithVisibleError item validate =
    let
        validation =
            validate item

        formElement =
            input
                [ type_ "hidden"
                , class (formControlClasses validation)
                ]
                []
    in
    div [ class "form-group" ]
        [ formElement
        , validationFeedback item validation
        ]


fieldIdentifier : String -> String
fieldIdentifier fieldName =
    String.toLower fieldName
        |> String.Extra.dasherize


formControlClasses : FieldValidation a -> String
formControlClasses validation =
    "form-control " ++ bootstrapValidationClass validation


bootstrapValidationClass : FieldValidation a -> String
bootstrapValidationClass validation =
    case validation of
        Valid ->
            "is-valid"

        Invalid _ ->
            "is-invalid"


validationFeedback : a -> FieldValidation a -> Html msg
validationFeedback item validation =
    div
        [ class "invalid-feedback" ]
        [ FieldValidation.error item validation |> text ]
