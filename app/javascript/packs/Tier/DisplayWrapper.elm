module Tier.DisplayWrapper
    exposing
        ( DisplayWrapper(..)
        , description
        , extractId
        , wrap
        )

import SelectList exposing (SelectList)
import Tier exposing (Tier)
import Tier.Level as Level exposing (Level)
import Utils


type DisplayWrapper
    = AvailableTier Tier
    | UnavailableTier Level


wrap : SelectList Tier -> SelectList DisplayWrapper
wrap availableTiers =
    let
        allLevels =
            SelectList.fromLists []
                Level.Zero
                [ Level.One, Level.Two, Level.Three ]

        wrapTierToDisplay =
            \level ->
                case tierWithLevel level of
                    Just tier ->
                        AvailableTier tier

                    Nothing ->
                        UnavailableTier level

        tierWithLevel =
            \level ->
                List.filter
                    (\tier -> tier.level == level)
                    (SelectList.toList availableTiers)
                    |> List.head

        reselectSelectedTier =
            \wrapper ->
                case wrapper of
                    AvailableTier tier ->
                        Utils.sameId tier.id (SelectList.selected availableTiers)

                    UnavailableTier _ ->
                        False
    in
    SelectList.map wrapTierToDisplay allLevels
        |> SelectList.select reselectSelectedTier


extractId : DisplayWrapper -> Int
extractId wrapper =
    case toTier wrapper of
        Just tier ->
            Tier.extractId tier

        Nothing ->
            -- Use this as a placeholder ID when we don't have a real Tier and
            -- so a real ID. Not ideal, but unlikely to ever cause a problem
            -- and simpler than changing everywhere we expect an Int id to
            -- accept a Maybe Int.
            -1


description : DisplayWrapper -> String
description wrapper =
    Level.description <| getLevel wrapper


getLevel : DisplayWrapper -> Level
getLevel wrapper =
    case wrapper of
        AvailableTier tier ->
            tier.level

        UnavailableTier level ->
            level


toTier : DisplayWrapper -> Maybe Tier
toTier wrapper =
    case wrapper of
        AvailableTier tier ->
            Just tier

        UnavailableTier _ ->
            Nothing
