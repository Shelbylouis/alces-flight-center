module Main exposing (..)

import CaseCategory exposing (CaseCategory)
import Cluster exposing (Cluster)
import Component exposing (Component)
import FieldValidation exposing (FieldValidation(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit)
import Http
import Issue exposing (Issue)
import Json.Decode as D
import Maybe.Extra
import Navigation
import Rails
import SelectList exposing (Position(..), SelectList)
import Service exposing (Service)
import ServiceType exposing (ServiceType)
import State exposing (State)
import Utils
import View.Fields as Fields
import View.PartsField as PartsField exposing (PartsFieldConfig(..))


-- MODEL


type Model
    = Initialized State
    | Error String


decodeInitialModel : D.Value -> Model
decodeInitialModel value =
    let
        result =
            D.decodeValue State.decoder value
    in
    case result of
        Ok state ->
            Initialized state

        Err message ->
            Error message



-- INIT


init : D.Value -> ( Model, Cmd Msg )
init flags =
    ( decodeInitialModel flags, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        Initialized state ->
            div []
                (Maybe.Extra.values
                    [ submitErrorAlert state
                    , caseForm state |> Just
                    ]
                )

        Error message ->
            span []
                [ text
                    ("Error initializing form: "
                        ++ message
                        ++ ". Please contact support@alces-software.com"
                    )
                ]


submitErrorAlert : State -> Maybe (Html Msg)
submitErrorAlert state =
    -- This closely matches the error alert we show from Rails, but is managed
    -- by Elm rather than Bootstrap JS.
    let
        displayError =
            \error ->
                errorAlert
                    [ button
                        [ type_ "button"
                        , class "close"
                        , attribute "aria-label" "Dismiss"
                        , onClick ClearError
                        ]
                        [ span [ attribute "aria-hidden" "true" ] [ text "×" ] ]
                    , text ("Error creating support case: " ++ error ++ ".")
                    ]
    in
    Maybe.map displayError state.error


errorAlert : List (Html msg) -> Html msg
errorAlert children =
    div
        [ class "alert alert-danger alert-dismissable fade show"
        , attribute "role" "alert"
        ]
        children


caseForm : State -> Html Msg
caseForm state =
    let
        formElements =
            Maybe.Extra.values
                [ maybeClustersField state.clusters
                , caseCategoriesField state |> Just
                , issuesField state |> Just
                , maybeComponentsField state
                , maybeServicesField state
                , detailsField state |> Just
                , submitButton state |> Just
                ]
    in
    Html.form [ onSubmit StartSubmit ] formElements


maybeClustersField : SelectList Cluster -> Maybe (Html Msg)
maybeClustersField clusters =
    let
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
            (Fields.selectField
                "Cluster"
                clusters
                Cluster.extractId
                .name
                (always Valid)
                ChangeSelectedCluster
            )


caseCategoriesField : State -> Html Msg
caseCategoriesField state =
    let
        validateCaseCategory =
            FieldValidation.validateWithEmptyError
                (CaseCategory.availableForSelectedCluster state.clusters)
    in
    Fields.selectField "Case category"
        state.caseCategories
        CaseCategory.extractId
        .name
        validateCaseCategory
        ChangeSelectedCaseCategory


issuesField : State -> Html Msg
issuesField state =
    let
        selectedCaseCategoryIssues =
            SelectList.selected state.caseCategories |> .issues

        validateIssue =
            FieldValidation.validateWithError
                """This cluster is self-managed; you may only request
                consultancy support from Alces Software."""
                (Issue.availableForSelectedCluster state.clusters)
    in
    Fields.selectField "Issue"
        selectedCaseCategoryIssues
        Issue.extractId
        Issue.name
        validateIssue
        ChangeSelectedIssue


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
    PartsField.maybePartsField "component"
        config
        Component.extractId
        Issue.requiresComponent
        state
        ChangeSelectedComponent


maybeServicesField : State -> Maybe (Html Msg)
maybeServicesField state =
    let
        serviceHasType =
            \serviceType ->
                .serviceType >> Utils.sameId serviceType.id

        servicePartName =
            "service"

        ( partName, config ) =
            if state.singleService then
                ( servicePartName, SinglePartField (State.selectedService state) )
            else
                case State.selectedIssue state |> Issue.serviceRequired of
                    ServiceType.None ->
                        ( servicePartName, NotRequired )

                    ServiceType.Any ->
                        ( servicePartName, SelectionField .services )

                    ServiceType.SpecificType serviceType ->
                        ( serviceType.name
                        , SubSetSelectionField .services (serviceHasType serviceType)
                        )
    in
    PartsField.maybePartsField partName
        config
        Service.extractId
        Issue.requiresService
        state
        ChangeSelectedService


detailsField : State -> Html Msg
detailsField state =
    let
        selectedIssue =
            State.selectedIssue state

        validateDetails =
            FieldValidation.validateWithEmptyError Issue.detailsValid
    in
    Fields.textareaField
        "Details"
        selectedIssue
        Issue.details
        validateDetails
        ChangeDetails


submitButton : State -> Html Msg
submitButton state =
    input
        [ type_ "submit"
        , value "Create Case"
        , class "btn btn-dark btn-block"
        , disabled (state.isSubmitting || State.isInvalid state)
        ]
        []



-- MESSAGE


type Msg
    = ChangeSelectedCluster String
    | ChangeSelectedCaseCategory String
    | ChangeSelectedIssue String
    | ChangeSelectedComponent String
    | ChangeSelectedService String
    | ChangeDetails String
    | StartSubmit
    | SubmitResponse (Result (Rails.Error String) ())
    | ClearError



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Initialized state ->
            let
                ( newState, cmd ) =
                    updateState msg state
                        |> Maybe.withDefault ( state, Cmd.none )
            in
            ( Initialized newState, cmd )

        Error message ->
            model ! []


updateState : Msg -> State -> Maybe ( State, Cmd Msg )
updateState msg state =
    case msg of
        ChangeSelectedCluster id ->
            stringToId Cluster.Id id
                |> Maybe.map (handleChangeSelectedCluster state)

        ChangeSelectedCaseCategory id ->
            stringToId CaseCategory.Id id
                |> Maybe.map (handleChangeSelectedCaseCategory state)

        ChangeSelectedIssue id ->
            stringToId Issue.Id id
                |> Maybe.map (handleChangeSelectedIssue state)

        ChangeSelectedComponent id ->
            stringToId Component.Id id
                |> Maybe.map (handleChangeSelectedComponent state)

        ChangeSelectedService id ->
            stringToId Service.Id id
                |> Maybe.map (handleChangeSelectedService state)

        ChangeDetails details ->
            Just
                ( handleChangeDetails state details, Cmd.none )

        StartSubmit ->
            Just
                ( { state | isSubmitting = True }
                , submitForm state
                )

        SubmitResponse result ->
            case result of
                Ok () ->
                    -- Success response indicates case was successfully
                    -- created, so redirect to root page.
                    Just ( state, Navigation.load "/" )

                Err error ->
                    Just
                        ( { state
                            | error = Just (formatSubmitError error)
                            , isSubmitting = False
                          }
                        , Cmd.none
                        )

        ClearError ->
            Just ( { state | error = Nothing }, Cmd.none )


stringToId : (Int -> id) -> String -> Maybe id
stringToId constructor idString =
    String.toInt idString
        |> Result.toMaybe
        |> Maybe.map constructor


handleChangeSelectedCluster : State -> Cluster.Id -> ( State, Cmd Msg )
handleChangeSelectedCluster state clusterId =
    let
        newClusters =
            SelectList.select (Utils.sameId clusterId) state.clusters
    in
    ( { state | clusters = newClusters }
    , Cmd.none
    )


handleChangeSelectedCaseCategory : State -> CaseCategory.Id -> ( State, Cmd Msg )
handleChangeSelectedCaseCategory state caseCategoryId =
    let
        newCaseCategories =
            SelectList.select (Utils.sameId caseCategoryId) state.caseCategories
    in
    updateSelectedServiceForSelectedIssue
        { state | caseCategories = newCaseCategories }
        ! []


handleChangeSelectedIssue : State -> Issue.Id -> ( State, Cmd Msg )
handleChangeSelectedIssue state issueId =
    let
        newCaseCategories =
            CaseCategory.setSelectedIssue state.caseCategories issueId
    in
    updateSelectedServiceForSelectedIssue
        { state | caseCategories = newCaseCategories }
        ! []


updateSelectedServiceForSelectedIssue : State -> State
updateSelectedServiceForSelectedIssue state =
    let
        serviceAllowedForSelectedIssue =
            State.selectedIssue state |> Issue.serviceAllowedFor

        selectedServiceAllowedForSelectedIssue =
            State.selectedService state |> serviceAllowedForSelectedIssue

        newClusters =
            if selectedServiceAllowedForSelectedIssue then
                state.clusters
            else
                Cluster.setSelectedServiceWhere
                    state.clusters
                    serviceAllowedForSelectedIssue
    in
    { state | clusters = newClusters }


handleChangeSelectedComponent : State -> Component.Id -> ( State, Cmd Msg )
handleChangeSelectedComponent state componentId =
    ( { state
        | clusters =
            Cluster.setSelectedComponent state.clusters componentId
      }
    , Cmd.none
    )


handleChangeSelectedService : State -> Service.Id -> ( State, Cmd Msg )
handleChangeSelectedService state serviceId =
    ( { state
        | clusters =
            Cluster.setSelectedService state.clusters serviceId
      }
    , Cmd.none
    )


handleChangeDetails : State -> String -> State
handleChangeDetails state details =
    let
        newCaseCategories =
            SelectList.mapBy updateSelectedCaseCategorySelectedIssue state.caseCategories

        updateSelectedCaseCategorySelectedIssue =
            \position ->
                \caseCategory ->
                    if position == Selected then
                        { caseCategory
                            | issues =
                                SelectList.mapBy updateSelectedIssueDetails caseCategory.issues
                        }
                    else
                        caseCategory

        updateSelectedIssueDetails =
            \position ->
                \issue ->
                    if position == Selected then
                        Issue.setDetails issue details
                    else
                        issue
    in
    { state | caseCategories = newCaseCategories }


submitForm : State -> Cmd Msg
submitForm state =
    let
        body =
            State.encoder state |> Http.jsonBody

        getErrors =
            D.field "errors" D.string
                |> Rails.decodeErrors
    in
    Rails.post "/cases" body (D.succeed ())
        |> Http.send (getErrors >> SubmitResponse)


formatSubmitError : Rails.Error String -> String
formatSubmitError error =
    case error.rails of
        Just errors ->
            errors

        Nothing ->
            formatHttpError error.http


formatHttpError : Http.Error -> String
formatHttpError error =
    case error of
        Http.BadUrl url ->
            "invalid URL: " ++ url

        Http.Timeout ->
            "request timed out"

        Http.NetworkError ->
            "unable to access network"

        Http.BadStatus { status } ->
            "unexpected response status: " ++ toString status.code

        Http.BadPayload message { status } ->
            "bad payload: " ++ message ++ "; status: " ++ toString status.code



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- MAIN


main : Program D.Value Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
