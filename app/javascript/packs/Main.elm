module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


-- MODEL


type alias Model =
    { clusters : List Cluster
    , caseCategories : List CaseCategory
    , components : List Component
    , formState : FormState
    }


type alias Cluster =
    { id : ClusterId
    , name : String
    }


type ClusterId
    = ClusterId Int


type alias CaseCategory =
    { id : CaseCategoryId
    , name : String
    , requiresComponent : Bool
    }


type CaseCategoryId
    = CaseCategoryId Int


type alias Component =
    { id : ComponentId
    , name : String
    , clusterId : ClusterId
    }


type ComponentId
    = ComponentId Int


type alias FormState =
    { selectedClusterId : Maybe ClusterId
    , selectedCaseCategoryId : Maybe CaseCategoryId
    , selectedComponentId : Maybe ComponentId
    , details : String
    }


clusterId : Cluster -> Int
clusterId cluster =
    case cluster.id of
        ClusterId id ->
            id


caseCategoryId : CaseCategory -> Int
caseCategoryId caseCategory =
    case caseCategory.id of
        CaseCategoryId id ->
            id


componentId : Component -> Int
componentId component =
    case component.id of
        ComponentId id ->
            id



-- INIT


init : ( Model, Cmd Msg )
init =
    let
        initialModel =
            { clusters =
                [ Cluster (ClusterId 1) "Foo cluster"
                , Cluster (ClusterId 2) "Bar cluster"
                ]
            , caseCategories =
                [ CaseCategory (CaseCategoryId 1) "Suspected hardware issue" True
                , CaseCategory (CaseCategoryId 2) "Request for gridware package" False
                ]
            , components =
                [ Component (ComponentId 1) "foonode01" (ClusterId 1)
                , Component (ComponentId 2) "foonode02" (ClusterId 1)
                ]
            , formState =
                { selectedClusterId = Nothing
                , selectedCaseCategoryId = Nothing
                , selectedComponentId = Nothing
                , details = ""
                }
            }
    in
    ( initialModel, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    Html.form []
        [ selectField "Cluster"
            "cluster_id"
            model.clusters
            clusterId
            .name
            ChangeSelectedCluster
        , selectField "Case category"
            "case_category_id"
            model.caseCategories
            caseCategoryId
            .name
            ChangeSelectedCaseCategory
        , selectField "Component"
            "component_id"
            model.components
            componentId
            .name
            ChangeSelectedComponent
        , textareaField "Details"
            "details"
            model.formState.details
            ChangeDetails
        , submitButton
        ]


selectField :
    String
    -> String
    -> List a
    -> (a -> Int)
    -> (a -> String)
    -> (String -> Msg)
    -> Html Msg
selectField fieldName fieldIdentifier items toId toOptionLabel changeMsg =
    let
        namespacedId =
            namespacedFieldId fieldIdentifier

        fieldOption =
            \item ->
                option
                    [ toId item |> toString |> value ]
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
                    stringToId ClusterId id

                newFormState =
                    { formState | selectedClusterId = selectedClusterId }
            in
            ( { model | formState = newFormState }, Cmd.none )

        ChangeSelectedCaseCategory id ->
            let
                selectedCaseCategoryId =
                    stringToId CaseCategoryId id

                newFormState =
                    { formState | selectedCaseCategoryId = selectedCaseCategoryId }
            in
            ( { model | formState = newFormState }, Cmd.none )

        ChangeSelectedComponent id ->
            let
                selectedComponentId =
                    stringToId ComponentId id

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
