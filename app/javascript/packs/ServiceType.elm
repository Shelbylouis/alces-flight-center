module ServiceType exposing (..)

import Json.Decode as D


-- At the moment ServiceType only has two fields and is just used in Issue and
-- Service, so it is stored denormalized within these for simplicity.


type alias ServiceType =
    { id : Id
    , name : String
    }


type Id
    = Id Int


type ServiceRequired
    = Any
    | SpecificType ServiceType
    | None


decoder : D.Decoder ServiceType
decoder =
    D.map2 ServiceType
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
