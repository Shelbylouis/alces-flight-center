module View.Fields
    exposing
        ( selectField
        , textField
        )

import Bootstrap.Badge as Badge
import Bootstrap.Utilities.Spacing as Spacing
import Field exposing (Field)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Json.Decode as D
import Maybe.Extra
import Msg exposing (Msg)
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
    -> (a -> Bool)
    -> (String -> msg)
    -> State
    -> Html msg
selectField field items toId toOptionLabel isDisabled changeMsg state =
    let
        fieldOption =
            \position item ->
                option
                    [ toId item |> toString |> value
                    , position == Selected |> selected
                    , isDisabled item |> disabled
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
        False
        Nothing
        state


type alias TextFieldConfig a =
    { fieldType : Types.TextField
    , field : Field
    , toContent : a -> String
    , inputMsg : String -> Msg
    , optional : Bool
    , help : Maybe String
    }


textField : TextFieldConfig a -> State -> a -> Html Msg
textField config state item =
    let
        content =
            config.toContent item

        ( element, additionalAttributes ) =
            case config.fieldType of
                Types.Input ->
                    ( input, [] )

                Types.TextArea ->
                    ( textarea, [ rows 10 ] )

        attributes =
            [ onInput config.inputMsg
            , value content
            ]
                ++ additionalAttributes
    in
    formField config.field
        item
        element
        attributes
        []
        config.optional
        config.help
        state


type alias HtmlFunction msg =
    List (Attribute msg) -> List (Html msg) -> Html msg


formField :
    Field
    -> a
    -> HtmlFunction msg
    -> List (Attribute msg)
    -> List (Html msg)
    -> Bool
    -> Maybe String
    -> State
    -> Html msg
formField field item htmlFn additionalAttributes children optional help state =
    let
        fieldName =
            case field of
                Field.TierField data ->
                    data.name

                _ ->
                    toString field

        fieldIsUnavailable =
            tierIsUnavailable && Field.isDynamicField field

        tierIsUnavailable =
            State.selectedTierSupportUnavailable state

        identifier =
            fieldIdentifier fieldName

        requiredBadge =
            if optional then
                text ""
            else
                Badge.badgeLight [ Spacing.ml1 ] [ text "Required" ]

        attributes =
            List.append
                [ id identifier
                , class (formControlClasses field errors)
                , disabled fieldIsUnavailable
                , attribute "aria-describedBy" helpIdentifier
                ]
                additionalAttributes

        formElement =
            htmlFn attributes children

        helpElement =
            case help of
                Just helpText ->
                    small
                        [ id helpIdentifier, class "form-text text-muted" ]
                        [ text helpText ]

                Nothing ->
                    text ""

        helpIdentifier =
            identifier ++ "-help"

        errors =
            Validation.validateField field state
    in
    div [ class "form-group" ]
        [ label
            [ for identifier ]
            [ text fieldName ]
        , requiredBadge
        , formElement
        , helpElement
        , validationFeedback errors
        ]


fieldIdentifier : String -> String
fieldIdentifier fieldName =
    String.toLower fieldName
        |> String.Extra.dasherize


formControlClasses : Field -> List Error -> String
formControlClasses field errors =
    "form-control " ++ bootstrapValidationClass field errors


bootstrapValidationClass : Field -> List Error -> String
bootstrapValidationClass field errors =
    let
        validationClass =
            if List.isEmpty errors then
                "is-valid"
            else
                "is-invalid"
    in
    if Field.hasBeenTouched field then
        validationClass
    else
        -- If the field is not considered to have been touched yet then just
        -- give nothing, rather than showing either success or failure, to
        -- avoid showing the user many errors for fields they haven't yet
        -- looked at.
        ""


validationFeedback : List Error -> Html msg
validationFeedback errors =
    let
        combinedErrorMessages =
            List.map unpackErrorMessage errorMessages
                |> Maybe.Extra.values
                |> String.join "; "

        errorMessages =
            List.map Tuple.second errors

        unpackErrorMessage =
            \error ->
                case error of
                    Empty ->
                        Nothing

                    Message message ->
                        Just message
    in
    div
        [ class "invalid-feedback" ]
        [ text combinedErrorMessages ]
