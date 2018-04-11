module Tier exposing (Tier, decoder, levelAsInt)

import Json.Decode as D


type alias Tier =
    { id : Id
    , level : Level
    , fields : List Field
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
    { type_ : TextInputType
    , name : String
    , value : String

    -- XXX Could encode `optional` in `Field` type like:
    -- | RequiredTextInput TextInput
    -- | OptionalTextInput TextInput
    , optional : Bool
    }


type
    TextInputType
    -- XXX Could unify with `View.Fields.TextField`.
    = Input
    | Textarea


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
        (D.field "fields" <| D.list fieldDecoder)
        |> D.andThen createTier


fieldDecoder : D.Decoder Field
fieldDecoder =
    let
        fieldTypeDecoder =
            \type_ ->
                case type_ of
                    "markdown" ->
                        markdownDecoder

                    "input" ->
                        textInputDecoder Input

                    "textarea" ->
                        textInputDecoder Textarea

                    _ ->
                        D.fail <| "Invalid type: " ++ type_
    in
    D.field "type" D.string
        |> D.andThen fieldTypeDecoder


markdownDecoder : D.Decoder Field
markdownDecoder =
    D.map Markdown <| D.field "content" D.string


textInputDecoder : TextInputType -> D.Decoder Field
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
