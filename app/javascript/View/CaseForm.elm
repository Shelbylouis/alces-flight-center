module View.CaseForm exposing (view)

import Bootstrap.Alert as Alert
import Bootstrap.Modal as Modal
import Category
import Cluster
import Component
import Dict
import DrillDownSelectList
import Field exposing (Field)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Attributes.Extra
import Html.Events exposing (onClick, onSubmit)
import Html.Keyed
import Issue
import Issues
import Markdown
import Msg exposing (..)
import SelectList
import Service
import State exposing (State)
import Tier exposing (Tier)
import Tier.DisplayWrapper exposing (DisplayWrapper)
import Tier.Field
import Tier.Level as Level exposing (Level)
import Types
import Validation
import View.Charging as Charging
import View.Fields as Fields
import View.PartsField as PartsField
import View.Utils


view : State -> Html Msg
view state =
    let
        submitMsg =
            if State.selectedTier state |> Tier.isChargeable then
                ChargeablePreSubmissionModal Modal.shown
            else
                StartSubmit

        formElements =
            [ issueDrillDownSection state
            , dynamicFieldsSection state
            ]
    in
    Html.form [ onSubmit submitMsg ] formElements


issueDrillDownSection : State -> Html Msg
issueDrillDownSection state =
    -- There's a certain amount of duplication between the logic here and in
    -- `Field.parentFieldHasBeenSelected`, as we need to find the same parent
    -- select lists but for a different purpose - consider DRYing these up.
    let
        keyedSection =
            Html.Keyed.node "section"

        issuesFieldKey =
            case State.selectedServiceIssues state of
                Issues.JustIssues _ ->
                    "issues-for-service-" ++ selectedServiceId

                Issues.CategorisedIssues categories ->
                    let
                        selectedCategoryId =
                            DrillDownSelectList.selected categories
                                |> .id
                                |> toString
                    in
                    "issues-for-category-" ++ selectedCategoryId

        selectedClusterId =
            State.selectedCluster state
                |> .id
                |> toString

        selectedServiceId =
            State.selectedService state
                |> .id
                |> toString

        selectedIssueId =
            State.selectedIssue state
                |> Issue.id
                |> toString
    in
    -- These fields allow a user to drill down to identify the particular Issue
    -- and possible solutions (via different Tiers) to a problem they are
    -- having.
    --
    -- We key each field in such a way that a new key is used each time the
    -- parent field, and therefore the items within each `select`, change. This
    -- prevents Elm from reusing different `select`s when this happens, which
    -- in turn is useful as `selected` is only applied to a `select` `option`
    -- on render, and so if a `select` is reused it can cause weird behaviour
    -- with the selected option not corresponding with the selected item in the
    -- model.
    keyedSection [] <|
        [ ( "drill-down-info", drillDownInfoAlert )
        , ( "clusters", clustersField state )
        , ( "services-for-cluster-" ++ selectedClusterId, servicesField state )
        , ( "categories-for-service-" ++ selectedServiceId, categoriesField state )
        , ( issuesFieldKey, issuesField state )
        , ( "components-for-issue-" ++ selectedIssueId, componentsField state )
        , ( "tiers-for-issue-" ++ selectedIssueId, tierTabs state )
        ]


dynamicFieldsSection : State -> Html Msg
dynamicFieldsSection state =
    -- These fields are very dynamic, and either appear/disappear entirely or
    -- have their content changed based on the currently selected Issue and
    -- Tier.
    let
        fields =
            case selectedTier.level of
                Level.Zero ->
                    -- When a level 0 Tier is selected we want to prevent filling in
                    -- any fields or submitting the form, and only show the rendered
                    -- Tier fields, which should include the relevant links to
                    -- documentation.
                    [ tierContentElements ]

                _ ->
                    [ subjectField state
                    , hr [] []
                    , tierContentElements
                    , submitButton state
                    ]

        attributes =
            if sectionDisabled then
                [ class "disabled-section"
                , title <| Validation.unavailableTierErrorMessage state
                ]
            else
                []

        sectionDisabled =
            State.selectedTierSupportUnavailable state

        selectedTier =
            State.selectedTier state

        tierContentElements =
            tierContent state
    in
    -- Hide everything in this section until the Tier field's parent (i.e. an
    -- Issue) has been selected, since until this has occurred don't know which
    -- Issue's fields to display and form cannot be submitted.
    View.Utils.showIfParentFieldSelected state Field.Tier <|
        section attributes fields


drillDownInfoAlert : Html msg
drillDownInfoAlert =
    -- Styling here adapted (i.e. converted from HTML to Elm) from
    -- `app/views/cases/_case_comment_toggle_controls.html.erb`.
    let
        infoIcon =
            i [ class "fa fa-info fa-2x mr-2" ] []

        alertContent =
            """
            Please attempt to classify your issue as much as possible by
            selecting from each box in turn, and then provide any further
            details needed. This helps Alces engineers better determine what
            problem you are facing and helps us resolve this faster.
            """
    in
    Alert.simpleInfo
        [ class "d-flex justify-content-between align-items-center" ]
        [ infoIcon
        , span
            [ style [ ( "flex-grow", "1" ) ] ]
            [ text alertContent ]
        ]


clustersField : State -> Html Msg
clustersField state =
    if State.singleClusterAvailable state then
        -- Only one Cluster available => no need to display Cluster selection
        -- field.
        View.Utils.nothing
    else
        Fields.selectField Field.Cluster
            state.clusters
            Cluster.extractId
            .name
            (always False)
            ChangeSelectedCluster
            state


categoriesField : State -> Html Msg
categoriesField state =
    State.selectedService state
        |> .issues
        |> Issues.categories
        |> Maybe.map
            (\categories_ ->
                Fields.selectField Field.Category
                    categories_
                    Category.extractId
                    .name
                    (always False)
                    ChangeSelectedCategory
                    state
            )
        |> Maybe.withDefault View.Utils.nothing


issuesField : State -> Html Msg
issuesField state =
    let
        selectedServiceAvailableIssues =
            State.selectedServiceAvailableIssues state
    in
    Fields.selectField Field.Issue
        selectedServiceAvailableIssues
        Issue.extractId
        Issue.name
        (always False)
        ChangeSelectedIssue
        state


tierTabs : State -> Html Msg
tierTabs state =
    let
        tabItems =
            SelectList.mapBy displayWrapperToTab wrappedTiers
                |> SelectList.toList

        wrappedTiers =
            State.selectedIssue state
                |> Issue.tiers
                |> Tier.DisplayWrapper.wrap

        tabs =
            -- Tab support is available in elm-bootstrap, but we do not use it
            -- at the moment as it is not really designed for a situation like
            -- ours, where the tab state is derived and changed based on the
            -- rest of the model rather than being an independent part of the
            -- model itself. Doing what we want with it seemed difficult and
            -- convoluted, if not impossible, with the current API.
            div []
                [ ul [ class "nav nav-tabs" ] tabItems

                -- Need hidden field and accompanying `invalid-feedback` `div`, which
                -- Bootstrap will use to decide whether to show any validation errors
                -- for the selected Tier.
                , Fields.hiddenFieldWithVisibleErrors Field.Tier state
                , Charging.chargeableAlert state
                    |> Maybe.withDefault View.Utils.nothing
                ]
    in
    -- Hide the Tier tabs until the Tier field's parent (i.e. an Issue) has
    -- been selected.
    View.Utils.showIfParentFieldSelected state Field.Tier tabs


displayWrapperToTab : SelectList.Position -> DisplayWrapper -> Html Msg
displayWrapperToTab position wrapper =
    let
        clickMsg =
            Tier.DisplayWrapper.extractId wrapper
                |> toString
                |> ChangeSelectedTier

        linkClasses =
            [ ( "nav-link", True )
            , ( "active", position == SelectList.Selected )
            , ( "disabled", Tier.DisplayWrapper.isUnavailable wrapper )
            ]

        titleText =
            if Tier.DisplayWrapper.isUnavailable wrapper then
                "Tier unavailable for selected issue"
            else
                ""
    in
    li [ class "nav-item" ]
        [ a
            [ classList linkClasses
            , onClick clickMsg
            , title titleText

            -- A `href` is required for Bootstrap to style the tabs correctly,
            -- and it needs this value as we don't want it to actually go
            -- anywhere (apart from what we handle in `onClick`).
            , href "javascript:void(0)"
            ]
            [ text <| Tier.DisplayWrapper.description wrapper ]
        ]


componentsField : State -> Html Msg
componentsField state =
    let
        issueRequiresComponent =
            State.selectedIssue state
                |> Issue.requiresComponent
    in
    if issueRequiresComponent then
        PartsField.partsField Field.Component
            .components
            Component.extractId
            state
            ChangeSelectedComponent
    else
        View.Utils.nothing


servicesField : State -> Html Msg
servicesField state =
    PartsField.partsField Field.Service
        .services
        Service.extractId
        state
        ChangeSelectedService


subjectField : State -> Html Msg
subjectField state =
    let
        selectedIssue =
            State.selectedIssue state

        textFieldConfig =
            { fieldType = Types.Input
            , field = Field.Subject
            , toContent = Issue.subject
            , inputMsg = ChangeSubject
            }
    in
    Fields.textField textFieldConfig state selectedIssue


tierContent : State -> Html Msg
tierContent state =
    let
        tier =
            State.selectedTier state

        content =
            case tier.content of
                Tier.Fields _ ->
                    renderedFields

                Tier.MotdTool _ ->
                    currentMotdAlert state :: renderedFields

        renderedFields =
            Tier.fields tier
                |> Dict.toList
                |> List.map (renderTierField state)
    in
    div [] content


renderTierField : State -> ( Int, Tier.Field.Field ) -> Html Msg
renderTierField state ( index, field ) =
    case field of
        Tier.Field.Markdown content ->
            Markdown.toHtml [] content

        Tier.Field.TextInput fieldData ->
            let
                textFieldConfig =
                    { fieldType = fieldData.type_
                    , field = Field.TierField fieldData
                    , toContent = .value
                    , inputMsg = ChangeTierField index
                    }
            in
            Fields.textField textFieldConfig state fieldData


currentMotdAlert : State -> Html msg
currentMotdAlert state =
    let
        cluster =
            State.selectedCluster state
    in
    Alert.simpleSecondary []
        [ Alert.h5 [] [ text "Current MOTD" ]
        , div [ Html.Attributes.Extra.innerHtml cluster.motdHtml ] []
        ]


submitButton : State -> Html Msg
submitButton state =
    input
        [ type_ "submit"
        , value "Create Case"
        , class "btn btn-primary btn-block"
        , disabled (state.isSubmitting || Validation.invalidState state)
        ]
        []
