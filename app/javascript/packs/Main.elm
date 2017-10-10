module Main exposing (..)

import CaseCategory exposing (CaseCategory)
import Cluster exposing (Cluster)
import Component exposing (Component)
import FieldValidation exposing (FieldValidation(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Issue exposing (Issue)
import Json.Decode as D
import Maybe.Extra
import Navigation
import Rails
import SelectList exposing (Position(..), SelectList)
import State exposing (State)
import String.Extra


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
        selectedClusterComponents =
            SelectList.selected state.clusters |> .components

        selectedCaseCategoryIssues =
            SelectList.selected state.caseCategories |> .issues

        selectedIssue =
            State.selectedIssue state

        clustersField =
            Just
                (selectField "Cluster"
                    state.clusters
                    Cluster.extractId
                    .name
                    (always Valid)
                    ChangeSelectedCluster
                )

        validateCaseCategory =
            FieldValidation.validateWithEmptyError
                (CaseCategory.availableForSelectedCluster state.clusters)

        caseCategoriesField =
            Just
                (selectField "Case category"
                    state.caseCategories
                    CaseCategory.extractId
                    .name
                    validateCaseCategory
                    ChangeSelectedCaseCategory
                )

        validateIssue =
            FieldValidation.validateWithError
                """This cluster is self-managed; you may only request
                consultancy support from Alces Software."""
                (Issue.availableForSelectedCluster state.clusters)

        issuesField =
            Just
                (selectField "Issue"
                    selectedCaseCategoryIssues
                    Issue.extractId
                    .name
                    validateIssue
                    ChangeSelectedIssue
                )

        componentsField =
            if selectedIssue.requiresComponent then
                Just
                    (selectField "Component"
                        selectedClusterComponents
                        Component.extractId
                        .name
                        (always Valid)
                        ChangeSelectedComponent
                    )
            else
                Nothing

        validateDetails =
            FieldValidation.validateWithEmptyError Issue.detailsValid

        detailsField =
            Just
                (textareaField
                    "Details"
                    selectedIssue
                    .details
                    validateDetails
                    ChangeDetails
                )

        formElements =
            Maybe.Extra.values
                [ clustersField
                , caseCategoriesField
                , issuesField
                , componentsField
                , detailsField
                , submitButton state |> Just
                ]
    in
    Html.form [ onSubmit StartSubmit ] formElements


selectField :
    String
    -> SelectList a
    -> (a -> Int)
    -> (a -> String)
    -> (a -> FieldValidation)
    -> (String -> Msg)
    -> Html Msg
selectField fieldName items toId toOptionLabel validate changeMsg =
    let
        identifier =
            fieldIdentifier fieldName

        validatedField =
            SelectList.selected items |> validate

        fieldOption =
            \position ->
                \item ->
                    option
                        [ toId item |> toString |> value
                        , position == Selected |> selected
                        , validate item |> FieldValidation.isInvalid |> disabled
                        ]
                        [ toOptionLabel item |> text ]

        options =
            SelectList.mapBy fieldOption items
                |> SelectList.toList

        classes =
            "form-control "
                ++ bootstrapValidationClass validatedField
    in
    div [ class "form-group" ]
        [ label
            [ for identifier ]
            [ text fieldName ]
        , select
            [ id identifier
            , class classes
            , onInput changeMsg
            ]
            options
        , div
            [ class "invalid-feedback" ]
            [ FieldValidation.error validatedField |> text ]
        ]


textareaField : String -> a -> (a -> String) -> (a -> FieldValidation) -> (String -> Msg) -> Html Msg
textareaField fieldName item toContent validate inputMsg =
    -- XXX De-duplicate this and `selectField`.
    let
        identifier =
            fieldIdentifier fieldName

        validatedField =
            validate item

        classes =
            "form-control "
                ++ bootstrapValidationClass validatedField

        content =
            toContent item
    in
    div [ class "form-group" ]
        [ label
            [ for identifier ]
            [ text fieldName ]
        , textarea
            [ id identifier
            , class classes
            , rows 10
            , onInput inputMsg
            , value content
            ]
            []
        ]


bootstrapValidationClass : FieldValidation -> String
bootstrapValidationClass validation =
    case validation of
        Valid ->
            "is-valid"

        Invalid _ ->
            "is-invalid"


fieldIdentifier : String -> String
fieldIdentifier fieldName =
    String.toLower fieldName
        |> String.Extra.dasherize


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
            SelectList.select (sameId clusterId) state.clusters
    in
    ( { state | clusters = newClusters }
    , Cmd.none
    )


handleChangeSelectedCaseCategory : State -> CaseCategory.Id -> ( State, Cmd Msg )
handleChangeSelectedCaseCategory state caseCategoryId =
    let
        newCaseCategories =
            SelectList.select (sameId caseCategoryId) state.caseCategories
    in
    ( { state | caseCategories = newCaseCategories }
    , Cmd.none
    )


handleChangeSelectedIssue : State -> Issue.Id -> ( State, Cmd Msg )
handleChangeSelectedIssue state issueId =
    let
        newCaseCategories =
            SelectList.mapBy updateSelectedCaseCategorySelectedIssue state.caseCategories

        updateSelectedCaseCategorySelectedIssue =
            \position ->
                \caseCategory ->
                    if position == Selected then
                        { caseCategory
                            | issues = SelectList.select (sameId issueId) caseCategory.issues
                        }
                    else
                        caseCategory
    in
    ( { state | caseCategories = newCaseCategories }
    , Cmd.none
    )


handleChangeSelectedComponent : State -> Component.Id -> ( State, Cmd Msg )
handleChangeSelectedComponent state componentId =
    let
        newClusters =
            SelectList.mapBy updateSelectedClusterSelectedComponent state.clusters

        updateSelectedClusterSelectedComponent =
            \position ->
                \cluster ->
                    if position == Selected then
                        { cluster
                            | components =
                                SelectList.select (sameId componentId) cluster.components
                        }
                    else
                        cluster
    in
    ( { state | clusters = newClusters }
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
                        { issue | details = details }
                    else
                        issue
    in
    { state | caseCategories = newCaseCategories }


sameId : b -> { a | id : b } -> Bool
sameId id item =
    item.id == id


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
