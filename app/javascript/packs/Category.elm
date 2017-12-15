module Category
    exposing
        ( Category
        , Id(..)
          -- , availableForSelectedCluster
        , decoder
        , extractId
        , filterByIssues
        , isControlledByService
        , setSelectedIssue
        )

import Cluster exposing (Cluster)
import Issue exposing (Issue)
import Json.Decode as D
import Maybe.Extra
import SelectList exposing (SelectList)
import SelectList.Extra
import Service exposing (Service)
import ServiceType exposing (ServiceType)
import Utils


type alias Category =
    { id : Id
    , name : String
    , issues : SelectList Issue
    , controllingServiceType : Maybe ServiceType
    }


type Id
    = Id Int


decoder : D.Decoder Category
decoder =
    D.map4 Category
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "issues" (SelectList.Extra.orderedDecoder Issue.name Issue.decoder))
        (D.field "controllingServiceType" (D.nullable ServiceType.decoder))



-- XXX disabled for now; may adapt and add back later when add back Categorys.
-- availableForSelectedCluster : SelectList Cluster -> Category -> Bool
-- availableForSelectedCluster clusters caseCategory =
--     -- A Category should be available only if any Issue within it is
--     -- available for the selected Cluster, otherwise there is no point allowing
--     -- selection of the Category.
--     SelectList.toList caseCategory.issues
--         |> List.any (Issue.Utils.availableForSelectedCluster clusters)


filterByIssues : SelectList Category -> (Issue -> Bool) -> Maybe (SelectList Category)
filterByIssues caseCategories condition =
    SelectList.map (withJustMatchingIssues condition) caseCategories
        |> SelectList.toList
        |> Maybe.Extra.values
        |> SelectList.Extra.fromList


withJustMatchingIssues : (Issue -> Bool) -> Category -> Maybe Category
withJustMatchingIssues condition caseCategory =
    SelectList.toList caseCategory.issues
        |> List.filter condition
        |> SelectList.Extra.fromList
        |> Maybe.map (asIssuesIn caseCategory)


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


{-|

    A Category is 'controlled by' a Service iff its
    `controllingServiceType` is the same as the Service's ServiceType.

-}
isControlledByService : Service -> Category -> Bool
isControlledByService service caseCategory =
    Maybe.map
        (Utils.sameId service.serviceType.id)
        caseCategory.controllingServiceType
        |> Maybe.withDefault False
