module Service exposing (..)

import Json.Decode as D
import ServiceType exposing (ServiceType)
import SupportType exposing (SupportType)


type alias Service =
    { id : Id
    , name : String
    , supportType : SupportType
    , serviceType : ServiceType
    }


type Id
    = Id Int


decoder : D.Decoder Service
decoder =
    D.map4 Service
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "supportType" SupportType.decoder)
        (D.field "serviceType" ServiceType.decoder)


extractId : Service -> Int
extractId component =
    case component.id of
        Id id ->
            id
