module Utils exposing (..)


sameId : b -> { a | id : b } -> Bool
sameId id item =
    item.id == id


othersLastComparison : String -> String
othersLastComparison item =
    -- If the item is the 'Other' one, which we use in different lists as the
    -- catch-all bucket so users can classify things that they don't otherwise
    -- know how to classify or that don't fit into an available option, then
    -- make sure this item appears last since it should always be considered
    -- after the more specific options.
    if isOtherCategorisation item then
        "ZZZZ" ++ item
    else
        item


isOtherCategorisation : String -> Bool
isOtherCategorisation item =
    -- This is a slightly hacky way to determine if an item is the 'Other'
    -- Issue/Category/Service etc. - since each of these is just a regular
    -- instance of their type as far as we're concerned, there's no way to
    -- determine if what we have is the 'Other' option apart from matching on
    -- the name.
    --
    -- A less hacky approach might be to add a database field identifying these
    -- and thread this all the way through to here, but since this approach
    -- works for now, it should only break if we start calling these things
    -- something other than 'Other', and if it does break nothing particularly
    -- bad will happen, it should be fine for now.
    String.startsWith "Other" item
