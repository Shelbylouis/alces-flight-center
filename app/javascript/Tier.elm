module Tier
    exposing
        ( Content(..)
        , Id(..)
        , Tier
        , decoder
        , encodeContentPair
        , extractId
        , fields
        , isChargeable
        , setFieldValue
        )

import Array
import Dict exposing (Dict)
import Field.Touched exposing (Touched(..))
import Json.Decode as D
import Json.Encode as E
import Maybe.Extra
import Tier.Field as Field exposing (Field)
import Tier.Level as Level exposing (Level)
import Types


type alias Tier =
    { id : Id
    , level : Level
    , content : Content
    }


type Id
    = Id Int


type Content
    = Fields FieldsDict
    | MotdTool FieldsDict


type alias FieldsDict =
    Dict Int Field


decoder : String -> D.Decoder Tier
decoder clusterMotd =
    D.field "level" D.int
        |> D.map Level.fromInt
        |> D.andThen
            (\levelResult ->
                case levelResult of
                    Ok level ->
                        D.map3 Tier
                            (D.field "id" D.int |> D.map Id)
                            (D.succeed level)
                            (contentDecoder clusterMotd)

                    Err error ->
                        D.fail error
            )


contentDecoder : String -> D.Decoder Content
contentDecoder clusterMotd =
    D.oneOf
        [ D.field "fields" fieldsDecoder
        , D.field "tool" (toolDecoder clusterMotd)
        ]


fieldsDecoder : D.Decoder Content
fieldsDecoder =
    let
        fieldDictDecoder =
            D.list Field.decoder
                |> D.map (List.indexedMap (,) >> Dict.fromList)
    in
    D.map Fields fieldDictDecoder


toolDecoder : String -> D.Decoder Content
toolDecoder clusterMotd =
    let
        decodeTool =
            \toolName ->
                case toolName of
                    "motd" ->
                        D.succeed <| motdTool clusterMotd

                    _ ->
                        D.fail <| "Unknown tool:" ++ toolName
    in
    D.string |> D.andThen decodeTool


motdTool : String -> Content
motdTool clusterMotd =
    let
        fields =
            Dict.fromList [ ( 1, motdField ) ]

        motdField =
            Field.TextInput
                { type_ = Types.TextArea
                , name = "New MOTD"
                , value = clusterMotd

                -- Can initially be considered touched as already contains
                -- content (the current MOTD).
                , touched = Touched
                , optional = False
                , help = Nothing
                }
    in
    MotdTool fields


encodeContentPair : Tier -> ( String, E.Value )
encodeContentPair tier =
    case tier.content of
        Fields fields ->
            ( "fields"
            , E.array
                (Dict.values fields
                    |> List.map Field.encoder
                    |> Maybe.Extra.values
                    |> Array.fromList
                )
            )

        MotdTool fields ->
            let
                motdFieldValue =
                    Dict.values fields
                        |> List.head
                        |> Maybe.map Field.data
                        |> Maybe.Extra.join
                        |> Maybe.map (.value >> E.string)
                        -- Should never happen, but this should cause an
                        -- obvious error if it ever somehow does.
                        |> Maybe.withDefault E.null
            in
            ( "tool_fields"
            , E.object
                [ ( "type", E.string "motd" )
                , ( "motd", motdFieldValue )
                ]
            )


extractId : Tier -> Int
extractId tier =
    case tier.id of
        Id id ->
            id


fields : Tier -> FieldsDict
fields tier =
    case tier.content of
        Fields fields ->
            fields

        MotdTool fields ->
            fields


setFieldValue : Tier -> Int -> String -> Tier
setFieldValue tier index value =
    let
        updateFieldValue =
            Maybe.map <| Field.replaceValue value

        updateFields =
            Dict.update index updateFieldValue

        newContent =
            case tier.content of
                Fields fields ->
                    Fields <| updateFields fields

                MotdTool fields ->
                    MotdTool <| updateFields fields
    in
    { tier | content = newContent }


isChargeable : Tier -> Bool
isChargeable tier =
    case tier.level of
        Level.Three ->
            True

        _ ->
            False
