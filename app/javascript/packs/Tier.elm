module Tier
    exposing
        ( Field(..)
        , Id(..)
        , TextInputData
        , Tier
        , decoder
        , description
        , extractId
        , levelAsInt
        , setFieldValue
        )

import Dict exposing (Dict)
import Json.Decode as D
import Types


type alias Tier =
    { id : Id
    , level : Level
    , fields : Dict Int Field
    }


type Id
    = Id Int


type Level
    = Zero
    | One
    | Two
    | Three


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
    let
        intermediateData =
            \id levelResult fields ->
                { id = id
                , levelResult = levelResult
                , fields = fields
                }

        createTier =
            \intermediate ->
                case intermediate.levelResult of
                    Ok level ->
                        D.succeed <|
                            Tier intermediate.id level intermediate.fields

                    Err error ->
                        D.fail error
    in
    D.map3 intermediateData
        (D.field "id" D.int |> D.map Id)
        (D.field "level" D.int |> D.map intToLevel)
        (D.field "fields" fieldsDecoder)
        |> D.andThen createTier


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


levelAsInt : Tier -> Int
levelAsInt tier =
    case tier.level of
        Zero ->
            0

        One ->
            1

        Two ->
            2

        Three ->
            3


intToLevel : Int -> Result String Level
intToLevel int =
    case int of
        0 ->
            Ok Zero

        1 ->
            Ok One

        2 ->
            Ok Two

        3 ->
            Ok Three

        _ ->
            Err <| "Invalid level: " ++ toString int


extractId : Tier -> Int
extractId tier =
    case tier.id of
        Id id ->
            id


description : Tier -> String
description tier =
    let
        humanTierDescription =
            case tier.level of
                Zero ->
                    "Guides"

                One ->
                    "Tool"

                Two ->
                    "Support"

                Three ->
                    "Consultancy"

        tierNumberPrefix =
            toString (levelAsInt tier) ++ ":"
    in
    String.join " "
        [ "Tier", tierNumberPrefix, humanTierDescription ]


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
