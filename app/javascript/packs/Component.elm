module Component exposing (..)

import Json.Decode as D
import SupportType exposing (SupportType)


type alias Component =
    { id : Id
    , name : String
    , supportType : SupportType
    }


type Id
    = Id Int


decoder : D.Decoder Component
decoder =
    D.map3 Component
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "supportType" SupportType.decoder)


extractId : Component -> Int
extractId component =
    case component.id of
        Id id ->
            id
