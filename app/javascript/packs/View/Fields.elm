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
import State exposing (State)
import String.Extra
import Validation exposing (Error, ErrorMessage(..))


selectField :
    Validation.Field
    -> SelectList a
    -> (a -> Int)
    -> (a -> String)
    -> (a -> FieldValidation a)
    -> (String -> msg)
    -> State
    -> Html msg
selectField field items toId toOptionLabel validate changeMsg state =
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
        state


textareaField :
    Validation.Field
    -> a
    -> (a -> String)
    -> (a -> FieldValidation a)
    -> (String -> msg)
    -> State
    -> Html msg
textareaField =
    textField TextArea


inputField :
    Validation.Field
    -> a
    -> (a -> String)
    -> (a -> FieldValidation a)
    -> (String -> msg)
    -> State
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
    -> State
    -> Html msg
textField textFieldType field item toContent validate inputMsg state =
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
        state


type alias HtmlFunction msg =
    List (Attribute msg) -> List (Html msg) -> Html msg


formField :
    Validation.Field
    -> a
    -> FieldValidation a
    -> HtmlFunction msg
    -> List (Attribute msg)
    -> List (Html msg)
    -> State
    -> Html msg
formField field item validation htmlFn additionalAttributes children state =
    let
        fieldName =
            toString field

        identifier =
            fieldIdentifier fieldName

        attributes =
            List.append
                [ id identifier
                , class (formControlClasses errors)
                ]
                additionalAttributes

        formElement =
            htmlFn attributes children

        errors =
            Validation.validateField field state
    in
    div [ class "form-group" ]
        [ label
            [ for identifier ]
            [ text fieldName ]
        , formElement
        , validationFeedback errors
        ]


hiddenInputWithVisibleError : a -> (a -> FieldValidation a) -> Html msg
hiddenInputWithVisibleError item validate =
    -- XXX Remove or replace this function?
    -- let
    --     validation =
    --         validate item
    --     formElement =
    --         input
    --             [ type_ "hidden"
    --             , class (formControlClasses validation)
    --             ]
    --             []
    -- in
    -- div [ class "form-group" ]
    --     [ formElement
    --     , validationFeedback item validation
    --     ]
    div [] []


fieldIdentifier : String -> String
fieldIdentifier fieldName =
    String.toLower fieldName
        |> String.Extra.dasherize


formControlClasses : List Error -> String
formControlClasses errors =
    "form-control " ++ bootstrapValidationClass errors


bootstrapValidationClass : List Error -> String
bootstrapValidationClass errors =
    if List.isEmpty errors then
        "is-valid"
    else
        "is-invalid"


validationFeedback : List Error -> Html msg
validationFeedback errors =
    let
        errorMessage =
            -- This elaborate pattern matching to just get an empty string is
            -- to remind me to actually display the error message(s) once we
            -- make it possible to set these (as this will then fail to
            -- compile).
            case List.head errors of
                Just ( field, Empty ) ->
                    ""

                Nothing ->
                    ""
    in
    div
        [ class "invalid-feedback" ]
        [ text errorMessage ]
