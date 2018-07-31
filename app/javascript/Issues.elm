module Issues
    exposing
        ( Issues(..)
        , availableIssues
        , categories
        , decoder
        , mapIssue
        , matchingIssues
        , selectCategory
        , selectIssue
        , selectedIssue
        )

import Category exposing (Category)
import DrillDownSelectList exposing (DrillDownSelectList)
import Issue exposing (Issue)
import Json.Decode as D
import Maybe.Extra
import SelectList.Extra
import Utils


type Issues
    = CategorisedIssues (DrillDownSelectList Category)
    | JustIssues (DrillDownSelectList Issue)


decoder : String -> D.Decoder Issues
decoder clusterMotd =
    let
        issueDecoder =
            Issue.decoder clusterMotd

        categoryDecoder =
            Category.decoder clusterMotd
    in
    D.oneOf
        [ SelectList.Extra.orderedDecoder Issue.name issueDecoder
            |> D.map DrillDownSelectList.Unselected
            |> D.map JustIssues
            |> D.field "issues"
        , SelectList.Extra.orderedDecoder .name categoryDecoder
            |> D.map DrillDownSelectList.Unselected
            |> D.map CategorisedIssues
            |> D.field "categories"
        ]


categories : Issues -> Maybe (DrillDownSelectList Category)
categories issues =
    case issues of
        CategorisedIssues categories ->
            Just categories

        JustIssues _ ->
            Nothing


mapIssue : (Issue -> Issue) -> Issues -> Issues
mapIssue transform issues =
    let
        updateIssue =
            DrillDownSelectList.mapSelected transform
    in
    case issues of
        CategorisedIssues categories ->
            DrillDownSelectList.mapSelected
                (\category ->
                    category.issues
                        |> updateIssue
                        |> Category.asIssuesIn category
                )
                categories
                |> CategorisedIssues

        JustIssues issues ->
            updateIssue issues |> JustIssues


selectIssue : Issue.Id -> Issues -> Issues
selectIssue issueId issues =
    case issues of
        CategorisedIssues categories ->
            Category.setSelectedIssue categories issueId
                |> CategorisedIssues

        JustIssues issues ->
            DrillDownSelectList.select (Issue.sameId issueId) issues
                |> JustIssues


selectedIssue : Issues -> Issue
selectedIssue issues =
    case issues of
        CategorisedIssues categories ->
            DrillDownSelectList.selected categories
                |> .issues
                |> DrillDownSelectList.selected

        JustIssues issues ->
            DrillDownSelectList.selected issues


selectCategory : Category.Id -> Issues -> Issues
selectCategory categoryId issues =
    case issues of
        CategorisedIssues categories ->
            DrillDownSelectList.select (Utils.sameId categoryId) categories
                |> CategorisedIssues

        JustIssues issues ->
            JustIssues issues


availableIssues : Issues -> DrillDownSelectList Issue
availableIssues issues =
    case issues of
        CategorisedIssues categories ->
            DrillDownSelectList.selected categories
                |> .issues

        JustIssues issues ->
            issues


matchingIssues : (Issue -> Bool) -> Issues -> Maybe Issues
matchingIssues condition issues =
    let
        filterIssues =
            \issues ->
                let
                    issuesConstructor =
                        case issues of
                            DrillDownSelectList.Selected _ ->
                                DrillDownSelectList.Selected

                            DrillDownSelectList.Unselected _ ->
                                DrillDownSelectList.Unselected
                in
                DrillDownSelectList.toList issues
                    |> List.filter condition
                    |> SelectList.Extra.fromList
                    |> Maybe.map issuesConstructor

        filterCategoriesAndIssues =
            \categories ->
                let
                    categoriesConstructor =
                        case categories of
                            DrillDownSelectList.Selected _ ->
                                DrillDownSelectList.Selected

                            DrillDownSelectList.Unselected _ ->
                                DrillDownSelectList.Unselected
                in
                DrillDownSelectList.toList categories
                    |> List.map
                        (\category ->
                            filterIssues category.issues
                                |> Maybe.map (Category.asIssuesIn category)
                        )
                    |> Maybe.Extra.values
                    |> SelectList.Extra.fromList
                    |> Maybe.map (categoriesConstructor >> CategorisedIssues)
    in
    case issues of
        CategorisedIssues categories ->
            filterCategoriesAndIssues categories

        JustIssues issues ->
            filterIssues issues
                |> Maybe.map JustIssues
