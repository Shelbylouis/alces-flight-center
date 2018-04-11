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
    | Details
