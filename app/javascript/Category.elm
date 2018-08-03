module Category
    exposing
        ( Category
        , Id(..)
        , asIssuesIn
        , decoder
        , extractId
        , setSelectedIssue
        )

import DrillDownSelectList exposing (DrillDownSelectList)
import Issue exposing (Issue)
import Json.Decode as D


type alias Category =
    { id : Id
    , name : String
    , issues : DrillDownSelectList Issue
    }


type Id
    = Id Int


decoder : String -> D.Decoder Category
decoder clusterMotd =
    D.map3 Category
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "issues" (Issue.issuesDecoder clusterMotd))


extractId : Category -> Int
extractId category =
    case category.id of
        Id id ->
            id


setSelectedIssue :
    DrillDownSelectList Category
    -> Issue.Id
    -> DrillDownSelectList Category
setSelectedIssue caseCategories issueId =
    DrillDownSelectList.nestedSelect
        caseCategories
        .issues
        asIssuesIn
        (Issue.sameId issueId)


asIssuesIn : Category -> DrillDownSelectList Issue -> Category
asIssuesIn category issues =
    { category | issues = issues }
