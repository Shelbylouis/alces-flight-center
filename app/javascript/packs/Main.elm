module Main exposing (..)

import CaseCategory exposing (CaseCategory)
import Cluster exposing (Cluster)
import Component exposing (Component)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Maybe.Extra


-- MODEL


type alias Model =
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
    }


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


selectedCaseCategory : Model -> Maybe CaseCategory
selectedCaseCategory model =
    let
        id =
            model.formState.selectedCaseCategoryId

        matchesId =
            \caseCategory ->
                Maybe.map ((==) caseCategory.id) id
                    |> Maybe.withDefault False
    in
    List.filter matchesId model.caseCategories
        |> List.head



-- INIT


init : ( Model, Cmd Msg )
init =
    let
        clusters =
            [ Cluster (Cluster.Id 1) "Foo cluster"
            , Cluster (Cluster.Id 2) "Bar cluster"
            ]

        caseCategories =
            [ CaseCategory (CaseCategory.Id 1) "Suspected hardware issue" True
            , CaseCategory (CaseCategory.Id 2) "Request for gridware package" False
            ]

        components =
            [ Component (Component.Id 1) "foonode01" (Cluster.Id 1)
            , Component (Component.Id 2) "foonode02" (Cluster.Id 1)
            ]

        firstId =
            \items -> List.head items |> Maybe.map .id

        initialModel =
            { clusters = clusters
            , caseCategories = caseCategories
            , components = components
            , formState =
                { selectedClusterId = firstId clusters
                , selectedCaseCategoryId = firstId caseCategories
                , selectedComponentId = firstId components
                , details = ""
                }
            }
    in
    ( initialModel, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    let
        clustersField =
            Just
                (selectField "Cluster"
                    "cluster_id"
                    (model.formState.selectedClusterId |> Maybe.map clusterIdToInt)
                    model.clusters
                    clusterId
                    .name
                    ChangeSelectedCluster
                )

        caseCategoriesField =
            Just
                (selectField "Case category"
                    "case_category_id"
                    (model.formState.selectedCaseCategoryId |> Maybe.map caseCategoryIdToInt)
                    model.caseCategories
                    caseCategoryId
                    .name
                    ChangeSelectedCaseCategory
                )

        componentsField =
            let
                currentClusterComponents =
                    case model.formState.selectedClusterId of
                        Just id ->
                            Component.forCluster id model.components

                        Nothing ->
                            []

                caseCategoryRequiresComponent =
                    selectedCaseCategory model
                        |> Maybe.map .requiresComponent
                        |> Maybe.withDefault False
            in
            if caseCategoryRequiresComponent then
                Just
                    (selectField "Component"
                        "component_id"
                        (model.formState.selectedComponentId |> Maybe.map componentIdToInt)
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
                    model.formState.details
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
    Html.form [] formElements


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
            [ name (formFieldIdentifier fieldIdentifier)
            , id namespacedId
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
            [ name (formFieldIdentifier fieldIdentifier)
            , id namespacedId
            , class "form-control"
            , rows 10
            , onInput inputMsg
            ]
            [ text content ]
        ]


namespacedFieldId : String -> String
namespacedFieldId fieldIdentifier =
    "new-case-form-" ++ fieldIdentifier


formFieldIdentifier : String -> String
formFieldIdentifier fieldIdentifier =
    "case[" ++ fieldIdentifier ++ "]"


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



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        formState =
            model.formState
    in
    case msg of
        ChangeSelectedCluster id ->
            let
                selectedClusterId =
                    stringToId Cluster.Id id

                newFormState =
                    { formState | selectedClusterId = selectedClusterId }
            in
            ( { model | formState = newFormState }, Cmd.none )

        ChangeSelectedCaseCategory id ->
            let
                selectedCaseCategoryId =
                    stringToId CaseCategory.Id id

                newFormState =
                    { formState | selectedCaseCategoryId = selectedCaseCategoryId }
            in
            ( { model | formState = newFormState }, Cmd.none )

        ChangeSelectedComponent id ->
            let
                selectedComponentId =
                    stringToId Component.Id id

                newFormState =
                    { formState | selectedComponentId = selectedComponentId }
            in
            ( { model | formState = newFormState }, Cmd.none )

        ChangeDetails details ->
            let
                newFormState =
                    { formState | details = details }
            in
            ( { model | formState = newFormState }, Cmd.none )


stringToId : (Int -> id) -> String -> Maybe id
stringToId constructor idString =
    String.toInt idString
        |> Result.toMaybe
        |> Maybe.map constructor



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- MAIN


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
