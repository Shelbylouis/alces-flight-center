module Issues
    exposing
        ( Issues
        , availableIssues
        , decoder
        , mapIssue
        , matchingIssues
        , selectIssue
        , selectedIssue
        )

import Category exposing (Category)
import Issue exposing (Issue)
import Json.Decode as D
import Maybe.Extra
import SelectList exposing (SelectList)
import SelectList.Extra


type Issues
    = CategorisedIssues (SelectList Category)
    | JustIssues (SelectList Issue)


decoder : D.Decoder Issues
decoder =
    D.oneOf
        [ SelectList.Extra.orderedDecoder Issue.name Issue.decoder
            |> D.map JustIssues
            |> D.field "issues"
        , SelectList.Extra.orderedDecoder .name Category.decoder
            |> D.map CategorisedIssues
            |> D.field "categories"
        ]


mapIssue : (Issue -> Issue) -> Issues -> Issues
mapIssue transform issues =
    let
        updateIssue =
            SelectList.Extra.mapSelected transform
    in
    case issues of
        CategorisedIssues categories ->
            SelectList.Extra.mapSelected
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
            SelectList.select (Issue.sameId issueId) issues
                |> JustIssues


selectedIssue : Issues -> Issue
selectedIssue issues =
    case issues of
        CategorisedIssues categories ->
            SelectList.selected categories
                |> .issues
                |> SelectList.selected

        JustIssues issues ->
            SelectList.selected issues


availableIssues : Issues -> SelectList Issue
availableIssues issues =
    case issues of
        CategorisedIssues categories ->
            SelectList.selected categories
                |> .issues

        JustIssues issues ->
            issues


matchingIssues : (Issue -> Bool) -> Issues -> Maybe Issues
matchingIssues condition issues =
    let
        filterIssues =
            \issues ->
                SelectList.toList issues
                    |> List.filter condition
                    |> SelectList.Extra.fromList
    in
    case issues of
        CategorisedIssues categories ->
            SelectList.toList categories
                |> List.map
                    (\category ->
                        filterIssues category.issues
                            |> Maybe.map (Category.asIssuesIn category)
                    )
                |> Maybe.Extra.values
                |> SelectList.Extra.fromList
                |> Maybe.map CategorisedIssues

        JustIssues issues ->
            filterIssues issues
                |> Maybe.map JustIssues
