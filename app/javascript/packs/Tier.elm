module Tier
    exposing
        ( Field(..)
        , Id(..)
        , TextInputData
        , Tier
        , decoder
        , extractId
        , fieldsEncoder
        , isChargeable
        , setFieldValue
        )

import Array
import Dict exposing (Dict)
import Json.Decode as D
import Json.Encode as E
import Maybe.Extra
import Tier.Level as Level exposing (Level)
import Types


type alias Tier =
    { id : Id
    , level : Level
    , fields : Dict Int Field
    }


type Id
    = Id Int


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


decoder : D.Decoder Tier
decoder =
    D.field "level" D.int
        |> D.map Level.fromInt
        |> D.andThen
            (\levelResult ->
                case levelResult of
                    Ok level ->
                        D.map3 Tier
                            (D.field "id" D.int |> D.map Id)
                            (D.succeed level)
                            (D.field "fields" fieldsDecoder)

                    Err error ->
                        D.fail error
            )


fieldsDecoder : D.Decoder (Dict Int Field)
fieldsDecoder =
    D.list fieldDecoder
        |> D.map (List.indexedMap (,) >> Dict.fromList)


fieldDecoder : D.Decoder Field
fieldDecoder =
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


fieldsEncoder : Tier -> E.Value
fieldsEncoder tier =
    E.array
        (Dict.values tier.fields
            |> List.map fieldEncoder
            |> Maybe.Extra.values
            |> Array.fromList
        )


fieldEncoder : Field -> Maybe E.Value
fieldEncoder field =
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


extractId : Tier -> Int
extractId tier =
    case tier.id of
        Id id ->
            id


setFieldValue : Tier -> Int -> String -> Tier
setFieldValue tier index value =
    let
        updateFieldValue =
            \maybeField ->
                case maybeField of
                    Just (Markdown f) ->
                        Just (Markdown f)

                    Just (TextInput f) ->
                        Just <| TextInput { f | value = value }

                    Nothing ->
                        Nothing
    in
    { tier
        | fields =
            Dict.update index updateFieldValue tier.fields
    }


isChargeable : Tier -> Bool
isChargeable tier =
    case tier.level of
        Level.Three ->
            True

        _ ->
            False
