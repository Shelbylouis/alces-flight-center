module Issue exposing (..)

import Json.Decode as D


type alias Issue =
    { id : Id
    , name : String
    , requiresComponent : Bool
    , details : String
    }


type Id
    = Id Int


decoder : D.Decoder Issue
decoder =
    D.map4 Issue
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
        (D.field "detailsTemplate" D.string)


extractId : Issue -> Int
extractId issue =
    case issue.id of
        Id id ->
            id
