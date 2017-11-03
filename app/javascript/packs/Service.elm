module Service exposing (..)

import Json.Decode as D
import SupportType exposing (SupportType)


type alias Service =
    { id : Id
    , name : String
    , supportType : SupportType
    }


type Id
    = Id Int


decoder : D.Decoder Service
decoder =
    D.map3 Service
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "supportType" SupportType.decoder)


extractId : Service -> Int
extractId component =
    case component.id of
        Id id ->
            id
