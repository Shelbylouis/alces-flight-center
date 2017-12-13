module SelectList.Extra
    exposing
        ( fromList
        , nameOrderedDecoder
        , nestedSelect
        , orderedDecoder
        , updateNested
        )

import Json.Decode as D
import SelectList exposing (Position(..), SelectList)


nameOrderedDecoder : D.Decoder { a | name : comparable } -> D.Decoder (SelectList { a | name : comparable })
nameOrderedDecoder =
    orderedDecoder .name


orderedDecoder : (a -> comparable) -> D.Decoder a -> D.Decoder (SelectList a)
orderedDecoder compare itemDecoder =
    let
        maybeToDecoder =
            \maybe ->
                case maybe of
                    Just selectList ->
                        D.succeed selectList

                    Nothing ->
                        D.fail "Failed to sort SelectList (should never happen?)"
    in
    decoder itemDecoder
        |> D.andThen
            (SelectList.toList
                >> List.sortBy compare
                >> fromList
                >> maybeToDecoder
            )


decoder : D.Decoder a -> D.Decoder (SelectList a)
decoder itemDecoder =
    let
        createSelectList =
            \list ->
                case fromList list of
                    Just selectList ->
                        D.succeed selectList

                    Nothing ->
                        D.fail "expected list with more than one element"
    in
    D.list itemDecoder |> D.andThen createSelectList


fromList : List a -> Maybe (SelectList a)
fromList list =
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


{-|

    Given a SelectList of `a`, where an `a` also contains a SelectList of `b`,
    update the selected `a` to change its SelectList of `b` to select the first
    `b` that isSelectable returns True for.

-}
nestedSelect :
    SelectList a
    -> (a -> SelectList b)
    -> (a -> SelectList b -> a)
    -> (b -> Bool)
    -> SelectList a
nestedSelect selectList getNested asNestedIn isSelectable =
    updateNested
        selectList
        getNested
        asNestedIn
        (SelectList.select isSelectable)


{-|

    As above but more general; apply an arbitrary `transform` to the nested
    SelectList.

-}
updateNested :
    SelectList a
    -> (a -> SelectList b)
    -> (a -> SelectList b -> a)
    -> (SelectList b -> SelectList b)
    -> SelectList a
updateNested selectList getNested asNestedIn transform =
    let
        updateNested =
            \position ->
                \item ->
                    if position == Selected then
                        getNested item
                            |> transform
                            |> asNestedIn item
                    else
                        item
    in
    SelectList.mapBy updateNested selectList
