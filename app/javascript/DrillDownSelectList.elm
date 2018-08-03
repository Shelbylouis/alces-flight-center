module DrillDownSelectList
    exposing
        ( DrillDownSelectList(..)
        , hasBeenSelected
        , mapSelected
        , nameOrderedDecoder
        , nestedSelect
        , orderedDecoder
        , select
        , selected
        , toList
        , unwrap
        , updateNested
        )

import Json.Decode as D
import SelectList exposing (SelectList)
import SelectList.Extra


type DrillDownSelectList a
    = Unselected (SelectList a)
    | Selected (SelectList a)



-- DrillDownSelectList-specific functions.


unwrap : DrillDownSelectList a -> SelectList a
unwrap selectList =
    case selectList of
        Unselected s ->
            s

        Selected s ->
            s


hasBeenSelected : DrillDownSelectList a -> Bool
hasBeenSelected selectList =
    case selectList of
        Unselected _ ->
            False

        Selected _ ->
            True


init : SelectList a -> DrillDownSelectList a
init selectList =
    let
        constructor =
            -- If only one option available no need to require user to select
            -- this, so initialize as Selected, otherwise initialize as
            -- Unselected so they must choose.
            if length == 1 then
                Selected
            else
                Unselected

        length =
            SelectList.toList selectList |> List.length
    in
    constructor selectList


{-| Map over the SelectList contained by the DrillDownSelectList.

    Note this does not map over the items of the contained SelectList itself,
    i.e.  it is not a wrapper for `SelectList.map`. If we later need that,
    possibly we should extract a new module for DrillDownSelectList's wrapper
    functions to avoid confusion over which functions operate on the SelectList
    as a whole vs the items within the SelectList.

-}
map :
    (SelectList a -> SelectList b)
    -> DrillDownSelectList a
    -> DrillDownSelectList b
map transform selectList =
    case selectList of
        Selected s ->
            Selected <| transform s

        Unselected s ->
            Unselected <| transform s



-- SelectList and SelectList.Extra wrapper functions.


select : (a -> Bool) -> DrillDownSelectList a -> DrillDownSelectList a
select isSelectable selectList =
    unwrap selectList
        |> SelectList.select isSelectable
        -- Once a DrillDownSelectList has been `select`ed we want it to always
        -- be Selected, since a user has now explicitly selected the option
        -- they want to use.
        |> Selected


selected : DrillDownSelectList a -> a
selected =
    unwrap >> SelectList.selected


mapSelected : (a -> a) -> DrillDownSelectList a -> DrillDownSelectList a
mapSelected transform selectList =
    map (SelectList.Extra.mapSelected transform) selectList


{-|

    Given a DrillDownSelectList of `a`, where an `a` also contains a
    DrillDownSelectList of `b`, update the selected `a` to change its
    DrillDownSelectList of `b` to select the first `b` that isSelectable
    returns True for.

-}
nestedSelect :
    DrillDownSelectList a
    -> (a -> DrillDownSelectList b)
    -> (a -> DrillDownSelectList b -> a)
    -> (b -> Bool)
    -> DrillDownSelectList a
nestedSelect selectList getNested asNestedIn isSelectable =
    updateNested
        selectList
        getNested
        asNestedIn
        (select isSelectable)


{-|

    As above but more general; apply an arbitrary `transform` to the nested
    DrillDownSelectList.

-}
updateNested :
    DrillDownSelectList a
    -> (a -> DrillDownSelectList b)
    -> (a -> DrillDownSelectList b -> a)
    -> (DrillDownSelectList b -> DrillDownSelectList b)
    -> DrillDownSelectList a
updateNested selectList getNested asNestedIn transform =
    let
        updateNested =
            \item ->
                getNested item
                    |> transform
                    |> asNestedIn item
    in
    mapSelected updateNested selectList


toList : DrillDownSelectList a -> List a
toList =
    unwrap >> SelectList.toList


nameOrderedDecoder :
    D.Decoder { a | name : comparable }
    -> D.Decoder (DrillDownSelectList { a | name : comparable })
nameOrderedDecoder =
    SelectList.Extra.nameOrderedDecoder >> D.map init


orderedDecoder :
    (a -> comparable)
    -> D.Decoder a
    -> D.Decoder (DrillDownSelectList a)
orderedDecoder compare =
    SelectList.Extra.orderedDecoder compare >> D.map init
