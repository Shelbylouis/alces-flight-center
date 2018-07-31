module Service exposing (..)

import Category exposing (Category)
import DrillDownSelectList exposing (DrillDownSelectList)
import Issue exposing (Issue)
import Issues exposing (Issues(..))
import Json.Decode as D
import Maybe.Extra
import SelectList exposing (SelectList)
import SelectList.Extra
import SupportType exposing (SupportType)
import Tier exposing (Tier)


type alias Service =
    { id : Id
    , name : String
    , supportType : SupportType
    , issues : Issues
    }


type Id
    = Id Int


filterByIssues : (Issue -> Bool) -> DrillDownSelectList Service -> Maybe (DrillDownSelectList Service)
filterByIssues condition servicesList =
    let
        filter services constructor =
            SelectList.map (withJustMatchingIssues condition) services
                |> SelectList.toList
                |> Maybe.Extra.values
                |> SelectList.Extra.fromList
                |> Maybe.map constructor
    in
    case servicesList of
        DrillDownSelectList.Selected services ->
            filter services DrillDownSelectList.Selected

        DrillDownSelectList.Unselected services ->
            filter services DrillDownSelectList.Unselected


withJustMatchingIssues : (Issue -> Bool) -> Service -> Maybe Service
withJustMatchingIssues condition service =
    Issues.matchingIssues condition service.issues
        |> Maybe.map (asIssuesIn service)


asIssuesIn : Service -> Issues -> Service
asIssuesIn service issues =
    { service | issues = issues }


decoder : String -> D.Decoder Service
decoder clusterMotd =
    D.map4 Service
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "supportType" SupportType.decoder)
        (Issues.decoder clusterMotd)


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


{-|

    Find the first Tier matching the given predicate and return a tuple
    containing it and all of its ancestors.

-}
findTierAndAncestors :
    (Tier -> Bool)
    -> SelectList Service
    -> Maybe ( Service, Maybe Category, Issue, Tier )
findTierAndAncestors predicate services =
    let
        findIssueAndTier :
            (Tier -> Bool)
            -> SelectList Issue
            -> Maybe ( Issue, Tier )
        findIssueAndTier predicate issues =
            let
                findTierAddingIssue issue =
                    Maybe.map ((,) issue) (Issue.findTier predicate issue)
            in
            SelectList.Extra.findValueBy findTierAddingIssue issues

        findCategoryIssueAndTier :
            (Tier -> Bool)
            -> SelectList Category
            -> Maybe ( Category, Issue, Tier )
        findCategoryIssueAndTier predicate categories =
            let
                findIssueAddingCategory cat =
                    case findIssueAndTier predicate cat.issues of
                        Just ( issue, tier ) ->
                            Just ( cat, issue, tier )

                        Nothing ->
                            Nothing
            in
            SelectList.Extra.findValueBy findIssueAddingCategory categories

        findServiceCategoryIssueAndTier :
            Service
            -> Maybe ( Service, Maybe Category, Issue, Tier )
        findServiceCategoryIssueAndTier service =
            case service.issues of
                Issues.CategorisedIssues categories ->
                    case findCategoryIssueAndTier predicate categories of
                        Just ( category, issue, tier ) ->
                            Just ( service, Just category, issue, tier )

                        _ ->
                            Nothing

                Issues.JustIssues issues ->
                    case findIssueAndTier predicate issues of
                        Just ( issue, tier ) ->
                            Just ( service, Nothing, issue, tier )

                        _ ->
                            Nothing
    in
    SelectList.Extra.findValueBy findServiceCategoryIssueAndTier services
