module Field exposing (..)

import Tier.Field


type Field
    = Cluster
    | Service
    | Category
    | Issue
    | Tier
    | Component
    | Subject
    | TierField Tier.Field.TextInputData


{-| The 'dynamic' fields are those shown in the lower section of the form,
whose value and/or presence frequently changes based on the selected Issue and
Tier.
-}
isDynamicField : Field -> Bool
isDynamicField field =
    case field of
        Subject ->
            True

        TierField _ ->
            True

        _ ->
            False


hasBeenTouched : Field -> Bool
hasBeenTouched field =
    case field of
        TierField data ->
            -- A Tier field has been touched if we have saved that we have
            -- touched it.
            case data.touched of
                Tier.Field.Touched ->
                    True

                Tier.Field.Untouched ->
                    False

        _ ->
            -- Always consider every other field touched, since they all start
            -- pre-filled.
            True
