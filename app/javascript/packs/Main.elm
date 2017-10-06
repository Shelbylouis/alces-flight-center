module Main exposing (..)

import CaseCategory exposing (CaseCategory)
import Cluster exposing (Cluster)
import Component exposing (Component)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as D
import Json.Encode as E
import Maybe.Extra exposing (isNothing, unwrap)
import Navigation
import Rails
import SelectList exposing (Position(..), SelectList)
import Utils


-- MODEL


type Model
    = Initialized State
    | Error String


type alias State =
    { clusters : SelectList Cluster
    , caseCategories : SelectList CaseCategory
    , details : String
    , error : Maybe String
    , isSubmitting : Bool
    }


decodeInitialModel : D.Value -> Model
decodeInitialModel value =
    let
        result =
            D.decodeValue initialStateDecoder value
    in
    case result of
        Ok state ->
            Initialized state

        Err message ->
            Error message


initialStateDecoder : D.Decoder State
initialStateDecoder =
    let
        createInitialState =
            \clusters ->
                \caseCategories ->
                    { clusters = clusters
                    , caseCategories = caseCategories
                    , details = ""
                    , error = Nothing
                    , isSubmitting = False
                    }
    in
    D.map2 createInitialState
        (D.field "clusters" <| Utils.selectListDecoder Cluster.decoder)
        (D.field "caseCategories" <| Utils.selectListDecoder CaseCategory.decoder)


formStateEncoder : State -> E.Value
formStateEncoder state =
    let
        selectedCaseCategory =
            SelectList.selected state.caseCategories

        selectedCluster =
            SelectList.selected state.clusters

        selectedComponent =
            SelectList.selected selectedCluster.components

        componentIdValue =
            if selectedCaseCategory.requiresComponent then
                componentIdToInt selectedComponent.id |> E.int
            else
                E.null
    in
    E.object
        [ ( "case"
          , E.object
                [ ( "cluster_id", clusterIdToInt selectedCluster.id |> E.int )
                , ( "case_category_id", caseCategoryIdToInt selectedCaseCategory.id |> E.int )
                , ( "component_id", componentIdValue )
                , ( "details", E.string state.details )
                ]
          )
        ]


formIsInvalid : State -> Bool
formIsInvalid state =
    String.isEmpty state.details


clusterId : Cluster -> Int
clusterId cluster =
    case cluster.id of
        Cluster.Id id ->
            id


caseCategoryId : CaseCategory -> Int
caseCategoryId caseCategory =
    case caseCategory.id of
        CaseCategory.Id id ->
            id


componentId : Component -> Int
componentId component =
    case component.id of
        Component.Id id ->
            id


clusterIdToInt : Cluster.Id -> Int
clusterIdToInt (Cluster.Id id) =
    id


caseCategoryIdToInt : CaseCategory.Id -> Int
caseCategoryIdToInt (CaseCategory.Id id) =
    id


componentIdToInt : Component.Id -> Int
componentIdToInt (Component.Id id) =
    id



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
                    [ errorAlert state
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


errorAlert : State -> Maybe (Html Msg)
errorAlert state =
    -- This closely matches the error alert we show from Rails, but is managed
    -- by Elm rather than Bootstrap JS.
    let
        displayError =
            \error ->
                div
                    [ class "alert alert-danger alert-dismissable fade show"
                    , attribute "role" "alert"
                    ]
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


caseForm : State -> Html Msg
caseForm state =
    let
        selectedCluster =
            SelectList.selected state.clusters

        selectedClusterComponents =
            selectedCluster.components

        selectedCaseCategory =
            SelectList.selected state.caseCategories

        clustersField =
            Just
                (selectField "Cluster"
                    "cluster_id"
                    state.clusters
                    clusterId
                    .name
                    ChangeSelectedCluster
                )

        caseCategoriesField =
            Just
                (selectField "Case category"
                    "case_category_id"
                    state.caseCategories
                    caseCategoryId
                    .name
                    ChangeSelectedCaseCategory
                )

        componentsField =
            if selectedCaseCategory.requiresComponent then
                Just
                    (selectField "Component"
                        "component_id"
                        selectedClusterComponents
                        componentId
                        .name
                        ChangeSelectedComponent
                    )
            else
                Nothing

        detailsField =
            Just
                (textareaField "Details"
                    "details"
                    state.details
                    ChangeDetails
                )

        formElements =
            Maybe.Extra.values
                [ clustersField
                , caseCategoriesField
                , componentsField
                , detailsField
                , submitButton state |> Just
                ]
    in
    Html.form [ onSubmit StartSubmit ] formElements


selectField :
    String
    -> String
    -> SelectList a
    -> (a -> Int)
    -> (a -> String)
    -> (String -> Msg)
    -> Html Msg
selectField fieldName fieldIdentifier items toId toOptionLabel changeMsg =
    let
        namespacedId =
            namespacedFieldId fieldIdentifier

        fieldOption =
            \position ->
                \item ->
                    option
                        [ toId item |> toString |> value
                        , position == Selected |> selected
                        ]
                        [ toOptionLabel item |> text ]

        options =
            SelectList.mapBy fieldOption items
                |> SelectList.toList
    in
    div [ class "form-group" ]
        [ label
            [ for namespacedId ]
            [ text fieldName ]
        , select
            [ id namespacedId
            , class "form-control"
            , onInput changeMsg
            ]
            options
        ]


textareaField : String -> String -> String -> (String -> Msg) -> Html Msg
textareaField fieldName fieldIdentifier content inputMsg =
    -- XXX De-duplicate this and `selectField`.
    let
        namespacedId =
            namespacedFieldId fieldIdentifier
    in
    div [ class "form-group" ]
        [ label
            [ for namespacedId ]
            [ text fieldName ]
        , textarea
            [ id namespacedId
            , class "form-control"
            , rows 10
            , onInput inputMsg
            ]
            [ text content ]
        ]


namespacedFieldId : String -> String
namespacedFieldId fieldIdentifier =
    "new-case-form-" ++ fieldIdentifier


submitButton : State -> Html Msg
submitButton state =
    input
        [ type_ "submit"
        , value "Create Case"
        , class "btn btn-dark btn-block"
        , disabled (state.isSubmitting || formIsInvalid state)
        ]
        []



-- MESSAGE


type Msg
    = ChangeSelectedCluster String
    | ChangeSelectedCaseCategory String
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

        ChangeSelectedComponent id ->
            stringToId Component.Id id
                |> Maybe.map (handleChangeSelectedComponent state)

        ChangeDetails details ->
            Just ( { state | details = details }, Cmd.none )

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


sameId : b -> { a | id : b } -> Bool
sameId id item =
    item.id == id


submitForm : State -> Cmd Msg
submitForm state =
    let
        body =
            formStateEncoder state |> Http.jsonBody

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
