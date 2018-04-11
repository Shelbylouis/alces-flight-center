module Tier exposing (..)

import Json.Decode as D


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


decoder : D.Decoder Tier
decoder =
    -- XXX Actually decode Tiers
    D.succeed
        { id = Id -1
        , level = One
        , fields = []
        }


levelAsInt : Tier -> Int
levelAsInt tier =
    case tier.level of
        Zero ->
            0

        One ->
            1

        Two ->
            2

        Three ->
            3
