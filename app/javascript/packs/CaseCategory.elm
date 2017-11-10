module CaseCategory
    exposing
        ( CaseCategory
        , Id(..)
        , availableForSelectedCluster
        , decoder
        , extractId
        , filterByIssues
        , setSelectedIssue
        )

import Cluster exposing (Cluster)
import Issue exposing (Issue)
import Json.Decode as D
import Maybe.Extra
import SelectList exposing (SelectList)
import SelectList.Extra
import ServiceType exposing (ServiceType)


type alias CaseCategory =
    { id : Id
    , name : String
    , issues : SelectList Issue
    , controllingServiceType : Maybe ServiceType
    }


type Id
    = Id Int


decoder : D.Decoder CaseCategory
decoder =
    D.map4 CaseCategory
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "issues" (SelectList.Extra.decoder Issue.decoder))
        (D.field "controllingServiceType" (D.nullable ServiceType.decoder))


availableForSelectedCluster : SelectList Cluster -> CaseCategory -> Bool
availableForSelectedCluster clusters caseCategory =
    -- A CaseCategory should be available only if any Issue within it is
    -- available for the selected Cluster, otherwise there is no point allowing
    -- selection of the CaseCategory.
    SelectList.toList caseCategory.issues
        |> List.any (Issue.availableForSelectedCluster clusters)


filterByIssues : SelectList CaseCategory -> (Issue -> Bool) -> Maybe (SelectList CaseCategory)
filterByIssues caseCategories condition =
    SelectList.map (withJustMatchingIssues condition) caseCategories
        |> SelectList.toList
        |> Maybe.Extra.values
        |> SelectList.Extra.fromList


withJustMatchingIssues : (Issue -> Bool) -> CaseCategory -> Maybe CaseCategory
withJustMatchingIssues condition caseCategory =
    SelectList.toList caseCategory.issues
        |> List.filter condition
        |> SelectList.Extra.fromList
        |> Maybe.map (asIssuesIn caseCategory)


extractId : CaseCategory -> Int
extractId caseCategory =
    case caseCategory.id of
        Id id ->
            id


setSelectedIssue : SelectList CaseCategory -> Issue.Id -> SelectList CaseCategory
setSelectedIssue caseCategories issueId =
    SelectList.Extra.nestedSelect
        caseCategories
        .issues
        asIssuesIn
        (Issue.sameId issueId)


asIssuesIn : CaseCategory -> SelectList Issue -> CaseCategory
asIssuesIn caseCategory issues =
    { caseCategory | issues = issues }
