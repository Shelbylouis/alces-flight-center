module CaseCategory exposing (..)

import Cluster exposing (Cluster)
import Issue exposing (Issue)
import Json.Decode as D
import SelectList exposing (SelectList)
import SelectList.Extra


type alias CaseCategory =
    { id : Id
    , name : String
    , issues : SelectList Issue
    }


type Id
    = Id Int


decoder : D.Decoder CaseCategory
decoder =
    D.map3 CaseCategory
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "issues" (SelectList.Extra.decoder Issue.decoder))


availableForSelectedCluster : SelectList Cluster -> CaseCategory -> Bool
availableForSelectedCluster clusters caseCategory =
    -- A CaseCategory should be available only if any Issue within it is
    -- available for the selected Cluster, otherwise there is no point allowing
    -- selection of the CaseCategory.
    SelectList.toList caseCategory.issues
        |> List.any (Issue.availableForSelectedCluster clusters)


filterByIssues : SelectList CaseCategory -> (Issue -> Bool) -> Maybe (SelectList CaseCategory)
filterByIssues caseCategories condition =
    let
        caseCategoryHasMatchingIssues =
            .issues >> SelectList.toList >> List.any condition
    in
    SelectList.toList caseCategories
        |> List.filter caseCategoryHasMatchingIssues
        |> SelectList.Extra.fromList


extractId : CaseCategory -> Int
extractId caseCategory =
    case caseCategory.id of
        Id id ->
            id
