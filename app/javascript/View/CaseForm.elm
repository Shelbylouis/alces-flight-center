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
import Issue
import Issues
import Markdown
import Maybe.Extra
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
import View.PartsField as PartsField exposing (PartsFieldConfig(..))
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
    -- These fields allow a user to drill down to identify the particular Issue
    -- and possible solutions (via different Tiers) to a problem they are
    -- having.
    section [] <|
        Maybe.Extra.values
            [ maybeClustersField state
            , maybeServicesField state
            , maybeCategoriesField state
            , issuesField state |> Just
            , maybeComponentsField state
            , tierTabs state |> Just
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
    section attributes fields


maybeClustersField : State -> Maybe (Html Msg)
maybeClustersField state =
    let
        clusters =
            state.clusters

        singleCluster =
            DrillDownSelectList.toList clusters
                |> List.length
                |> (==) 1
    in
    if singleCluster then
        -- Only one Cluster available => no need to display Cluster selection
        -- field.
        Nothing
    else
        Just
            (Fields.selectField Field.Cluster
                clusters
                Cluster.extractId
                .name
                (always False)
                ChangeSelectedCluster
                state
            )


maybeCategoriesField : State -> Maybe (Html Msg)
maybeCategoriesField state =
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
    in
    -- Tab support is available in elm-bootstrap, but we do not use it at the
    -- moment as it is not really designed for a situation like ours, where the
    -- tab state is derived and changed based on the rest of the model rather
    -- than being an independent part of the model itself. Doing what we want
    -- with it seemed difficult and convoluted, if not impossible, with the
    -- current API.
    div []
        [ ul [ class "nav nav-tabs" ] tabItems

        -- Need hidden field and accompanying `invalid-feedback` `div`, which
        -- Bootstrap will use to decide whether to show any validation errors
        -- for the selected Tier.
        , Fields.hiddenFieldWithVisibleErrors Field.Tier state
        , Charging.chargeableAlert state
            |> Maybe.withDefault View.Utils.nothing
        ]


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


maybeComponentsField : State -> Maybe (Html Msg)
maybeComponentsField state =
    let
        config =
            if State.selectedIssue state |> Issue.requiresComponent |> not then
                NotRequired
            else if state.singleComponent then
                SinglePartField (State.selectedComponent state)
            else
                SelectionField .components
    in
    PartsField.maybePartsField Field.Component
        config
        Component.extractId
        state
        ChangeSelectedComponent


maybeServicesField : State -> Maybe (Html Msg)
maybeServicesField state =
    let
        config =
            if state.singleComponent && singleServiceApplicable then
                -- No need to allow selection of a Service if we're in single
                -- Component mode and there's only one Service with Issues
                -- which require a Component.
                NotRequired
            else if state.singleService then
                SinglePartField (State.selectedService state)
            else
                SelectionField .services

        singleServiceApplicable =
            DrillDownSelectList.toList state.clusters
                |> List.length
                |> (==) 1
    in
    PartsField.maybePartsField Field.Service
        config
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
            , optional = False
            , help = Nothing
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
                    , optional = fieldData.optional
                    , help = fieldData.help
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
