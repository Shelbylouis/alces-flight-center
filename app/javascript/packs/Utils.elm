module Utils exposing (..)


sameId : b -> { a | id : b } -> Bool
sameId id item =
    item.id == id
