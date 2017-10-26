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
                case selectListFromList list of
                    Just selectList ->
                        D.succeed selectList

                    Nothing ->
                        D.fail "expected list with more than one element"
    in
    D.list itemDecoder |> D.andThen createSelectList


selectListFromList : List a -> Maybe (SelectList a)
selectListFromList list =
    let
        ( maybeHead, maybeTail ) =
            ( List.head list, List.tail list )
    in
    Maybe.map2
        (\head ->
            \tail ->
                SelectList.fromLists [] head tail
        )
        maybeHead
        maybeTail
