module CaseCategory exposing (..)

import Cluster exposing (Cluster)
import Issue exposing (Issue)
import Json.Decode as D
import SelectList exposing (SelectList)
import Utils


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
        (D.field "issues" (Utils.selectListDecoder Issue.decoder))


availableForSelectedCluster : SelectList Cluster -> CaseCategory -> Bool
availableForSelectedCluster clusters caseCategory =
    -- A CaseCategory should be available only if any Issue within it is
    -- available for the selected Cluster, otherwise there is no point allowing
    -- selection of the CaseCategory.
    SelectList.toList caseCategory.issues
        |> List.any (Issue.availableForSelectedCluster clusters)


hasAnyIssueRequiringComponent : CaseCategory -> Bool
hasAnyIssueRequiringComponent caseCategory =
    SelectList.toList caseCategory.issues
        |> List.any .requiresComponent


hasAnyIssueRequiringService : CaseCategory -> Bool
hasAnyIssueRequiringService caseCategory =
    SelectList.toList caseCategory.issues
        |> List.any .requiresService


extractId : CaseCategory -> Int
extractId caseCategory =
    case caseCategory.id of
        Id id ->
            id
