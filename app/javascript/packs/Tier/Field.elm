module Tier.Field exposing (Field(..), TextInputData, decoder, encoder)

import Json.Decode as D
import Json.Encode as E
import Types


type Field
    = Markdown String
    | TextInput TextInputData


type alias TextInputData =
    { type_ : Types.TextField
    , name : String
    , value : String

    -- XXX Could encode `optional` in `Field` type like:
    -- | RequiredTextInput TextInput
    -- | OptionalTextInput TextInput
    , optional : Bool
    }


decoder : D.Decoder Field
decoder =
    let
        fieldTypeDecoder =
            \type_ ->
                case type_ of
                    "markdown" ->
                        markdownDecoder

                    "input" ->
                        textInputDecoder Types.Input

                    "textarea" ->
                        textInputDecoder Types.TextArea

                    _ ->
                        D.fail <| "Invalid type: " ++ type_
    in
    D.field "type" D.string
        |> D.andThen fieldTypeDecoder


markdownDecoder : D.Decoder Field
markdownDecoder =
    D.map Markdown <| D.field "content" D.string


textInputDecoder : Types.TextField -> D.Decoder Field
textInputDecoder type_ =
    let
        initialValueDecoder =
            D.succeed ""

        optionalDecoder =
            D.field "optional" D.bool
                |> D.maybe
                |> D.map (Maybe.withDefault False)
    in
    D.map TextInput <|
        D.map4 TextInputData
            (D.succeed type_)
            (D.field "name" D.string)
            initialValueDecoder
            optionalDecoder


encoder : Field -> Maybe E.Value
encoder field =
    case field of
        Markdown _ ->
            Nothing

        TextInput data ->
            Just <|
                E.object
                    [ ( "type", textFieldTypeToString data.type_ |> E.string )
                    , ( "name", E.string data.name )
                    , ( "value", E.string data.value )
                    , ( "optional", E.bool data.optional )
                    ]


textFieldTypeToString : Types.TextField -> String
textFieldTypeToString field =
    case field of
        Types.TextArea ->
            "textarea"

        Types.Input ->
            "input"
