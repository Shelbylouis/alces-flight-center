module Service exposing (..)

import Category exposing (Category)
import Issue exposing (Issue)
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


type Issues
    = CategorisedIssues (SelectList Category)
    | JustIssues (SelectList Issue)


filterByIssues : (Issue -> Bool) -> SelectList Service -> Maybe (SelectList Service)
filterByIssues condition services =
    SelectList.map (withJustMatchingIssues condition) services
        |> SelectList.toList
        |> Maybe.Extra.values
        |> SelectList.Extra.fromList


withJustMatchingIssues : (Issue -> Bool) -> Service -> Maybe Service
withJustMatchingIssues condition service =
    let
        filterIssues =
            \issues ->
                SelectList.toList issues
                    |> List.filter condition
                    |> SelectList.Extra.fromList
    in
    case service.issues of
        CategorisedIssues categories ->
            SelectList.toList categories
                |> List.map
                    (\category ->
                        filterIssues category.issues
                            |> Maybe.map (Category.asIssuesIn category)
                    )
                |> Maybe.Extra.values
                |> SelectList.Extra.fromList
                |> Maybe.map (CategorisedIssues >> asIssuesIn service)

        JustIssues issues ->
            filterIssues issues
                |> Maybe.map (JustIssues >> asIssuesIn service)


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
        issuesDecoder


issuesDecoder : D.Decoder Issues
issuesDecoder =
    D.oneOf
        [ SelectList.Extra.orderedDecoder Issue.name Issue.decoder
            |> D.map JustIssues
            |> D.field "issues"
        , SelectList.Extra.orderedDecoder .name Category.decoder
            |> D.map CategorisedIssues
            |> D.field "categories"
        ]


extractId : Service -> Int
extractId component =
    case component.id of
        Id id ->
            id


setSelectedIssue : Issue.Id -> Service -> Service
setSelectedIssue issueId service =
    { service
        | issues =
            case service.issues of
                CategorisedIssues categories ->
                    Category.setSelectedIssue categories issueId
                        |> CategorisedIssues

                JustIssues issues ->
                    SelectList.select (Issue.sameId issueId) issues
                        |> JustIssues
    }


selectedIssueInIssues : Issues -> Issue
selectedIssueInIssues issues =
    case issues of
        CategorisedIssues categories ->
            SelectList.selected categories
                |> .issues
                |> SelectList.selected

        JustIssues issues ->
            SelectList.selected issues
