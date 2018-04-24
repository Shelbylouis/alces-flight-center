module Tier
    exposing
        ( Id(..)
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
import Types


type alias Tier =
    { id : Id
    , level : Level
    , fields : Dict Int Field
    }


type Id
    = Id Int


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
    D.list Field.decoder
        |> D.map (List.indexedMap (,) >> Dict.fromList)


fieldsEncoder : Tier -> E.Value
fieldsEncoder tier =
    E.array
        (Dict.values tier.fields
            |> List.map Field.encoder
            |> Maybe.Extra.values
            |> Array.fromList
        )


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
                    Just (Field.Markdown f) ->
                        Just (Field.Markdown f)

                    Just (Field.TextInput f) ->
                        Just <| Field.TextInput { f | value = value }

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
