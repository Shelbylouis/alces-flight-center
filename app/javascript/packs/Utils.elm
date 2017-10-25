module Utils exposing (..)

import Json.Decode as D
import SelectList exposing (SelectList)


sameId : b -> { a | id : b } -> Bool
sameId id item =
    item.id == id


selectListDecoder : D.Decoder a -> D.Decoder (SelectList a)
selectListDecoder itemDecoder =
    let
        createSelectList =
            \list ->
                let
                    ( maybeHead, maybeTail ) =
                        ( List.head list, List.tail list )
                in
                Maybe.map2
                    (\head ->
                        \tail ->
                            D.succeed (SelectList.fromLists [] head tail)
                    )
                    maybeHead
                    maybeTail
                    |> Maybe.withDefault (D.fail "expected list with more than one element")
    in
    D.list itemDecoder |> D.andThen createSelectList
