module View.CaseForm exposing (view)

import Bootstrap.Alert as Alert
import Bootstrap.Modal as Modal
import Category
import Cluster
import Component
import Dict
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
import Tier.DisplayWrapper
import Tier.Field
import Tier.Level as Level exposing (Level)
import Types
import Validation
import View.Charging as Charging
import View.Fields as Fields
import View.PartsField as PartsField exposing (PartsFieldConfig(..))


view : State -> Html Msg
view state =
    let
        submitMsg =
            if State.selectedTier state |> Tier.isChargeable then
                ChargeablePreSubmissionModal Modal.shown
            else
                StartSubmit

        formElements =
            [ issueDrillDownFields state
            , hr [] []
            , dynamicFields state
            ]
    in
    Html.form [ onSubmit submitMsg ] formElements


issueDrillDownFields : State -> Html Msg
issueDrillDownFields state =
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
            , tierSelectField state |> Just
            , Charging.chargeableAlert state
            ]


dynamicFields : State -> Html Msg
dynamicFields state =
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
            SelectList.toList clusters
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


tierSelectField : State -> Html Msg
tierSelectField state =
    let
        wrappedTiers =
            State.selectedIssue state
                |> Issue.tiers
                |> Tier.DisplayWrapper.wrap
    in
    Fields.selectField Field.Tier
        wrappedTiers
        Tier.DisplayWrapper.extractId
        Tier.DisplayWrapper.description
        Tier.DisplayWrapper.isUnavailable
        ChangeSelectedTier
        state


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
            SelectList.toList state.clusters
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
                Tier.Fields fields ->
                    Dict.toList fields
                        |> List.map (renderTierField state)

                Tier.MotdTool ->
                    [ currentMotdAlert state ]
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
