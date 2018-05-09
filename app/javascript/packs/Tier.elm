module Tier
    exposing
        ( Content(..)
        , Id(..)
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
import Tier.Field as Field exposing (Field)
import Tier.Level as Level exposing (Level)


type alias Tier =
    { id : Id
    , level : Level
    , content : Content
    }


type Id
    = Id Int


type Content
    = Fields (Dict Int Field)
    | MotdTool


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
                            contentDecoder

                    Err error ->
                        D.fail error
            )


contentDecoder : D.Decoder Content
contentDecoder =
    D.oneOf
        [ D.field "fields" fieldsDecoder
        , D.field "tool" toolDecoder
        ]


fieldsDecoder : D.Decoder Content
fieldsDecoder =
    let
        fieldDictDecoder =
            D.list Field.decoder
                |> D.map (List.indexedMap (,) >> Dict.fromList)
    in
    D.map Fields fieldDictDecoder


toolDecoder : D.Decoder Content
toolDecoder =
    let
        decodeTool =
            \toolName ->
                case toolName of
                    "motd" ->
                        D.succeed MotdTool

                    _ ->
                        D.fail <| "Unknown tool:" ++ toolName
    in
    D.string |> D.andThen decodeTool


fieldsEncoder : Tier -> E.Value
fieldsEncoder tier =
    case tier.content of
        Fields fields ->
            E.array
                (Dict.values fields
                    |> List.map Field.encoder
                    |> Maybe.Extra.values
                    |> Array.fromList
                )

        MotdTool ->
            -- XXX Do something useful
            E.null


extractId : Tier -> Int
extractId tier =
    case tier.id of
        Id id ->
            id


setFieldValue : Tier -> Int -> String -> Tier
setFieldValue tier index value =
    let
        updateFieldValue =
            Maybe.map <| Field.replaceValue value

        newContent =
            case tier.content of
                Fields fields ->
                    Fields <| Dict.update index updateFieldValue fields

                x ->
                    x
    in
    { tier | content = newContent }


isChargeable : Tier -> Bool
isChargeable tier =
    case tier.level of
        Level.Three ->
            True

        _ ->
            False
