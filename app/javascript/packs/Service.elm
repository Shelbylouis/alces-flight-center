module Service exposing (..)

import Category exposing (Category)
import Issue exposing (Issue)
import Issues exposing (Issues(..))
import Json.Decode as D
import Maybe.Extra
import SelectList exposing (SelectList)
import SelectList.Extra
import ServiceType exposing (ServiceType)
import SupportType exposing (SupportType)


type alias Service =
    { id : Id
    , name : String
    , supportType : SupportType
    , serviceType : ServiceType
    , issues : Issues
    }


type Id
    = Id Int


filterByIssues : (Issue -> Bool) -> SelectList Service -> Maybe (SelectList Service)
filterByIssues condition services =
    SelectList.map (withJustMatchingIssues condition) services
        |> SelectList.toList
        |> Maybe.Extra.values
        |> SelectList.Extra.fromList


withJustMatchingIssues : (Issue -> Bool) -> Service -> Maybe Service
withJustMatchingIssues condition service =
    Issues.matchingIssues condition service.issues
        |> Maybe.map (asIssuesIn service)


asIssuesIn : Service -> Issues -> Service
asIssuesIn service issues =
    { service | issues = issues }


decoder : D.Decoder Service
decoder =
    D.map5 Service
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "supportType" SupportType.decoder)
        (D.field "serviceType" ServiceType.decoder)
        Issues.decoder


extractId : Service -> Int
extractId component =
    case component.id of
        Id id ->
            id


setSelectedIssue : Issue.Id -> Service -> Service
setSelectedIssue issueId service =
    Issues.selectIssue issueId service.issues
        |> asIssuesIn service


setSelectedCategory : Category.Id -> Service -> Service
setSelectedCategory categoryId service =
    Issues.selectCategory categoryId service.issues
        |> asIssuesIn service
