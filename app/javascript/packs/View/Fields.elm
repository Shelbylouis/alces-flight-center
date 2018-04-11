module View.Fields
    exposing
        ( inputField
        , selectField
        , textareaField
        )

import Field exposing (Field)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Json.Decode as D
import SelectList exposing (Position(..), SelectList)
import State exposing (State)
import String.Extra
import Types
import Validation exposing (Error, ErrorMessage(..))


selectField :
    Field
    -> SelectList a
    -> (a -> Int)
    -> (a -> String)
    -> (String -> msg)
    -> State
    -> Html msg
selectField field items toId toOptionLabel changeMsg state =
    let
        fieldOption =
            \position item ->
                option
                    [ toId item |> toString |> value
                    , position == Selected |> selected
                    ]
                    [ toOptionLabel item |> text ]

        options =
            SelectList.mapBy fieldOption items
                |> SelectList.toList
    in
    formField field
        (SelectList.selected items)
        select
        [ Html.Events.on "change" (D.map changeMsg Html.Events.targetValue) ]
        options
        state


textareaField :
    Field
    -> a
    -> (a -> String)
    -> (String -> msg)
    -> State
    -> Html msg
textareaField =
    textField Types.TextArea


inputField :
    Field
    -> a
    -> (a -> String)
    -> (String -> msg)
    -> State
    -> Html msg
inputField =
    textField Types.Input


textField :
    Types.TextField
    -> Field
    -> a
    -> (a -> String)
    -> (String -> msg)
    -> State
    -> Html msg
textField textFieldType field item toContent inputMsg state =
    let
        content =
            toContent item

        ( element, additionalAttributes ) =
            case textFieldType of
                Types.Input ->
                    ( input, [] )

                Types.TextArea ->
                    ( textarea, [ rows 10 ] )

        attributes =
            [ onInput inputMsg
            , value content
            ]
                ++ additionalAttributes
    in
    formField field
        item
        element
        attributes
        []
        state


type alias HtmlFunction msg =
    List (Attribute msg) -> List (Html msg) -> Html msg


formField :
    Field
    -> a
    -> HtmlFunction msg
    -> List (Attribute msg)
    -> List (Html msg)
    -> State
    -> Html msg
formField field item htmlFn additionalAttributes children state =
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
