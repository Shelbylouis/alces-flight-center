module Field.Touched exposing (..)


type
    Touched
    -- This is essentially a Bool, but use a custom type to force us to be
    -- explicit about what we're doing and prevent accidentally using it in the
    -- wrong place, at the expense of being slightly more verbose.
    = Touched
    | Untouched
