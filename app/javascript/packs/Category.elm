module Category
    exposing
        ( Category
        , Id(..)
        , asIssuesIn
          -- , availableForSelectedCluster
        , decoder
        , extractId
        , setSelectedIssue
        )

import Issue exposing (Issue)
import Json.Decode as D
import SelectList exposing (SelectList)
import SelectList.Extra


type alias Category =
    { id : Id
    , name : String
    , issues : SelectList Issue
    }


type Id
    = Id Int


decoder : D.Decoder Category
decoder =
    D.map3 Category
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "issues" (SelectList.Extra.orderedDecoder Issue.name Issue.decoder))



-- XXX disabled for now; may adapt and add back later when add back Categorys.
-- availableForSelectedCluster : SelectList Cluster -> Category -> Bool
-- availableForSelectedCluster clusters caseCategory =
--     -- A Category should be available only if any Issue within it is
--     -- available for the selected Cluster, otherwise there is no point allowing
--     -- selection of the Category.
--     SelectList.toList caseCategory.issues
--         |> List.any (Issue.Utils.availableForSelectedCluster clusters)


extractId : Category -> Int
extractId caseCategory =
    case caseCategory.id of
        Id id ->
            id


setSelectedIssue : SelectList Category -> Issue.Id -> SelectList Category
setSelectedIssue caseCategories issueId =
    SelectList.Extra.nestedSelect
        caseCategories
        .issues
        asIssuesIn
        (Issue.sameId issueId)


asIssuesIn : Category -> SelectList Issue -> Category
asIssuesIn caseCategory issues =
    { caseCategory | issues = issues }
