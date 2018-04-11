module Tier exposing (..)


type alias Tier =
    { id : Id
    , level : Level
    , fields : List Field
    }


type Id
    = Id Int


type Level
    = Zero
    | One
    | Two
    | Three


type Field
    = Markdown String
    | TextInput TextInputData


type alias TextInputData =
    { type_ : TextInputType
    , name : String
    , value : String

    -- XXX Could encode `optional` in `Field` type like:
    -- | RequiredTextInput TextInput
    -- | OptionalTextInput TextInput
    , optional : Bool
    }


type
    TextInputType
    -- XXX Could unify with `View.Fields.TextField`.
    = Input
    | Textarea
