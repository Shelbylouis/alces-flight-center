module Tier.Field
    exposing
        ( Field(..)
        , TextInputData
        , data
        , decoder
        , encoder
        , replaceValue
        )

import Field.Touched exposing (Touched(..))
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

    -- Whether this field has been touched yet by a user.
    , touched : Touched
    , optional : Bool
    , help : Maybe String
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
        D.map6 TextInputData
            (D.succeed type_)
            (D.field "name" D.string)
            initialValueDecoder
            -- Every field is initially untouched.
            (D.succeed Untouched)
            optionalDecoder
            (D.maybe (D.field "help" D.string))


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
                    , ( "help", Maybe.map E.string data.help |> Maybe.withDefault E.null )
                    , ( "optional", E.bool data.optional )
                    ]


textFieldTypeToString : Types.TextField -> String
textFieldTypeToString field =
    case field of
        Types.TextArea ->
            "textarea"

        Types.Input ->
            "input"


data : Field -> Maybe TextInputData
data field =
    case field of
        Markdown _ ->
            Nothing

        TextInput d ->
            Just d


replaceValue : String -> Field -> Field
replaceValue value field =
    case field of
        Markdown s ->
            Markdown s

        TextInput d ->
            TextInput
                { d
                    | value = value
                    , touched = Touched
                }
