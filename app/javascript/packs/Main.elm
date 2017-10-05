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
import Maybe.Extra
import Navigation
import Rails


-- MODEL


type Model
    = Initialized State
    | Error String


type alias State =
    { clusters : List Cluster
    , caseCategories : List CaseCategory
    , components : List Component
    , formState : FormState
    }


type alias FormState =
    { selectedClusterId : Maybe Cluster.Id
    , selectedCaseCategoryId : Maybe CaseCategory.Id
    , selectedComponentId : Maybe Component.Id
    , details : String
    , error : Maybe String
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
        firstId =
            \items -> List.head items |> Maybe.map .id

        createInitialState =
            \clusters ->
                \caseCategories ->
                    \components ->
                        State clusters
                            caseCategories
                            components
                            { selectedClusterId = firstId clusters
                            , selectedCaseCategoryId = firstId caseCategories
                            , selectedComponentId = firstId components
                            , details = ""
                            , error = Nothing
                            }
    in
    D.map3 createInitialState
        (D.field "clusters" (D.list Cluster.decoder))
        (D.field "caseCategories" (D.list CaseCategory.decoder))
        (D.field "components" (D.list Component.decoder))


formStateEncoder : FormState -> Maybe E.Value
formStateEncoder formState =
    let
        -- Encode value only if all select fields have value selected.
        formCompleteEncoder =
            Maybe.map3
                (\clusterId ->
                    \caseCategoryId ->
                        \componentId ->
                            E.object
                                [ ( "case"
                                  , E.object
                                        [ ( "cluster_id", clusterIdToInt clusterId |> E.int )
                                        , ( "case_category_id", caseCategoryIdToInt caseCategoryId |> E.int )
                                        , ( "component_id", componentIdToInt componentId |> E.int )
                                        , ( "details", E.string formState.details )
                                        ]
                                  )
                                ]
                )
    in
    formCompleteEncoder
        formState.selectedClusterId
        formState.selectedCaseCategoryId
        formState.selectedComponentId


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


selectedCaseCategory : State -> Maybe CaseCategory
selectedCaseCategory state =
    let
        id =
            state.formState.selectedCaseCategoryId

        matchesId =
            \caseCategory ->
                Maybe.map ((==) caseCategory.id) id
                    |> Maybe.withDefault False
    in
    List.filter matchesId state.caseCategories
        |> List.head



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
                    [ errorAlert state.formState
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


errorAlert : FormState -> Maybe (Html Msg)
errorAlert formState =
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
    Maybe.map displayError formState.error


caseForm : State -> Html Msg
caseForm state =
    let
        clustersField =
            Just
                (selectField "Cluster"
                    "cluster_id"
                    (state.formState.selectedClusterId |> Maybe.map clusterIdToInt)
                    state.clusters
                    clusterId
                    .name
                    ChangeSelectedCluster
                )

        caseCategoriesField =
            Just
                (selectField "Case category"
                    "case_category_id"
                    (state.formState.selectedCaseCategoryId |> Maybe.map caseCategoryIdToInt)
                    state.caseCategories
                    caseCategoryId
                    .name
                    ChangeSelectedCaseCategory
                )

        componentsField =
            let
                currentClusterComponents =
                    case state.formState.selectedClusterId of
                        Just id ->
                            Component.forCluster id state.components

                        Nothing ->
                            []

                caseCategoryRequiresComponent =
                    selectedCaseCategory state
                        |> Maybe.map .requiresComponent
                        |> Maybe.withDefault False
            in
            if caseCategoryRequiresComponent then
                Just
                    (selectField "Component"
                        "component_id"
                        (state.formState.selectedComponentId |> Maybe.map componentIdToInt)
                        currentClusterComponents
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
                    state.formState.details
                    ChangeDetails
                )

        formElements =
            Maybe.Extra.values
                [ clustersField
                , caseCategoriesField
                , componentsField
                , detailsField
                , Just submitButton
                ]
    in
    Html.form [ onSubmit StartSubmit ] formElements


selectField :
    String
    -> String
    -> Maybe Int
    -> List a
    -> (a -> Int)
    -> (a -> String)
    -> (String -> Msg)
    -> Html Msg
selectField fieldName fieldIdentifier selectedItemId items toId toOptionLabel changeMsg =
    let
        namespacedId =
            namespacedFieldId fieldIdentifier

        fieldOption =
            \item ->
                let
                    isSelected =
                        case selectedItemId of
                            Just id ->
                                id == toId item

                            Nothing ->
                                False
                in
                option
                    [ toId item |> toString |> value
                    , selected isSelected
                    ]
                    [ toOptionLabel item |> text ]
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
            (List.map fieldOption items)
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


submitButton : Html Msg
submitButton =
    input
        [ type_ "submit"
        , value "Create Case"
        , class "btn btn-dark btn-block"
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
            in
            ( Initialized newState, cmd )

        Error message ->
            model ! []


updateState : Msg -> State -> ( State, Cmd Msg )
updateState msg state =
    let
        formState =
            state.formState
    in
    case msg of
        ChangeSelectedCluster id ->
            let
                selectedClusterId =
                    stringToId Cluster.Id id

                newFormState =
                    { formState | selectedClusterId = selectedClusterId }
            in
            ( { state | formState = newFormState }, Cmd.none )

        ChangeSelectedCaseCategory id ->
            let
                selectedCaseCategoryId =
                    stringToId CaseCategory.Id id

                newFormState =
                    { formState | selectedCaseCategoryId = selectedCaseCategoryId }
            in
            ( { state | formState = newFormState }, Cmd.none )

        ChangeSelectedComponent id ->
            let
                selectedComponentId =
                    stringToId Component.Id id

                newFormState =
                    { formState | selectedComponentId = selectedComponentId }
            in
            ( { state | formState = newFormState }, Cmd.none )

        ChangeDetails details ->
            let
                newFormState =
                    { formState | details = details }
            in
            ( { state | formState = newFormState }, Cmd.none )

        StartSubmit ->
            ( state, submitForm state.formState )

        SubmitResponse result ->
            case result of
                Ok () ->
                    -- Success response indicates case was successfully
                    -- created, so redirect to root page.
                    ( state, Navigation.load "/" )

                Err error ->
                    let
                        newFormState =
                            { formState
                                | error = Just (formatSubmitError error)
                            }
                    in
                    ( { state | formState = newFormState }, Cmd.none )

        ClearError ->
            let
                newFormState =
                    { formState | error = Nothing }
            in
            ( { state | formState = newFormState }, Cmd.none )


stringToId : (Int -> id) -> String -> Maybe id
stringToId constructor idString =
    String.toInt idString
        |> Result.toMaybe
        |> Maybe.map constructor


submitForm : FormState -> Cmd Msg
submitForm formState =
    let
        maybeBody =
            formStateEncoder formState
                |> Maybe.map Http.jsonBody

        getErrors =
            D.field "errors" D.string
                |> Rails.decodeErrors
    in
    case maybeBody of
        Just body ->
            Rails.post "/cases" body (D.succeed ())
                |> Http.send (getErrors >> SubmitResponse)

        Nothing ->
            -- Do not do anything if form is not in a state to be submitted -
            -- XXX maybe should do something however?
            Cmd.none


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
