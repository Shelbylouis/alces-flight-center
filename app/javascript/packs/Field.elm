module Field exposing (..)

import Tier


type Field
    = Cluster
    | Service
    | Category
    | Issue
    | Tier
    | Component
    | Subject
    | TierField Tier.TextInputData


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
