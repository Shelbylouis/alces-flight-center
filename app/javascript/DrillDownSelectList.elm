module DrillDownSelectList exposing (..)

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



-- XXX Rename arguments and/or simplify functions in this file?
-- XXX Or pull in or reference docs from SelectList.Extra?


select : (a -> Bool) -> DrillDownSelectList a -> DrillDownSelectList a
select isSelectable selectList =
    Selected <|
        case selectList of
            Unselected s ->
                SelectList.select isSelectable s

            Selected s ->
                SelectList.select isSelectable s


selected : DrillDownSelectList a -> a
selected selectList =
    -- XXX Should this actually return a Maybe, with Nothing when nothing yet
    -- selected?
    case selectList of
        Unselected s ->
            SelectList.selected s

        Selected s ->
            SelectList.selected s


mapSelected : (a -> a) -> DrillDownSelectList a -> DrillDownSelectList a
mapSelected transform selectList =
    Selected <|
        case selectList of
            Unselected s ->
                SelectList.Extra.mapSelected transform s

            Selected s ->
                SelectList.Extra.mapSelected transform s


nestedDrillDownSelect :
    SelectList a
    -> (a -> DrillDownSelectList b)
    -> (a -> DrillDownSelectList b -> a)
    -> (b -> Bool)
    -> SelectList a
nestedDrillDownSelect selectList getNested asNestedIn isSelectable =
    -- XXX Rename as with `updateNestedDrillDownSelectList`?
    updateNestedDrillDownSelectList
        selectList
        getNested
        asNestedIn
        (select isSelectable)


updateNestedDrillDownSelectList :
    -- XXX Collapse back into simple `updateNested` function?
    -- XXX Can this just use function from SelectList.Extra?
    SelectList a
    -> (a -> DrillDownSelectList b)
    -> (a -> DrillDownSelectList b -> a)
    -> (DrillDownSelectList b -> DrillDownSelectList b)
    -> SelectList a
updateNestedDrillDownSelectList selectList getNested asNestedIn transform =
    let
        updateNested =
            \item ->
                getNested item
                    |> transform
                    |> asNestedIn item
    in
    SelectList.Extra.mapSelected updateNested selectList
