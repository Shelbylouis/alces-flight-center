module Service exposing (..)

import Issue exposing (Issue)
import Json.Decode as D
import SelectList exposing (SelectList)
import SelectList.Extra
import ServiceType exposing (ServiceType)
import SupportType exposing (SupportType)


type alias Service =
    { id : Id
    , name : String
    , supportType : SupportType
    , serviceType : ServiceType
    , issues : SelectList Issue
    }


type Id
    = Id Int


asIssuesIn : Service -> SelectList Issue -> Service
asIssuesIn service issues =
    { service | issues = issues }


decoder : D.Decoder Service
decoder =
    D.map5 Service
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "supportType" SupportType.decoder)
        (D.field "serviceType" ServiceType.decoder)
        (D.field "issues" (SelectList.Extra.orderedDecoder Issue.name Issue.decoder))


extractId : Service -> Int
extractId component =
    case component.id of
        Id id ->
            id
