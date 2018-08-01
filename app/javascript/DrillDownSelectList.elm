module DrillDownSelectList
    exposing
        ( DrillDownSelectList(..)
        , hasBeenSelected
        , mapSelected
        , nestedSelect
        , select
        , selected
        , toList
        , unwrap
        , updateNested
        )

import SelectList exposing (SelectList)
import SelectList.Extra


type DrillDownSelectList a
    = Unselected (SelectList a)
    | Selected (SelectList a)


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



-- XXX Consider distinguishing these functions more - functions above are
-- DrillDownSelectList-specific, whereas those below are just wrappers around
-- SelectList functions.
-- XXX Rename arguments and/or simplify functions in this file?
-- XXX Or pull in or reference docs from SelectList.Extra?


select : (a -> Bool) -> DrillDownSelectList a -> DrillDownSelectList a
select isSelectable selectList =
    unwrap selectList
        |> SelectList.select isSelectable
        -- XXX Document why this always returns `Selected`?
        |> Selected


selected : DrillDownSelectList a -> a
selected =
    -- XXX Should this actually return a Maybe, with Nothing when nothing yet
    -- selected?
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
    -- XXX Collapse back into simple `updateNested` function?
    -- XXX Can this just use function from SelectList.Extra?
    DrillDownSelectList a
    -> (a -> DrillDownSelectList b)
    -> (a -> DrillDownSelectList b -> a)
    -> (DrillDownSelectList b -> DrillDownSelectList b)
    -> DrillDownSelectList a
updateNested selectList getNested asNestedIn transform =
    -- XXX Can this just use function from SelectList.Extra?
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
