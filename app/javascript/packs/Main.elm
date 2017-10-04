module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


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
        [ selectField "Cluster" "cluster_id" model.clusters .name
        , selectField "Case category" "case_category_id" model.caseCategories .name
        , selectField "Component" "component_id" model.components .name
        , textareaField "Details" "details" model.formState.details
        , submitButton
        ]


selectField : String -> String -> List a -> (a -> String) -> Html Msg
selectField fieldName fieldIdentifier items toOptionLabel =
    let
        namespacedId =
            namespacedFieldId fieldIdentifier

        fieldOption =
            \item -> option [] [ toOptionLabel item |> text ]
    in
    div [ class "form-group" ]
        [ label
            [ for namespacedId ]
            [ text fieldName ]
        , select
            [ name (formFieldIdentifier fieldIdentifier)
            , id namespacedId
            , class "form-control"
            ]
            (List.map fieldOption items)
        ]


textareaField : String -> String -> String -> Html Msg
textareaField fieldName fieldIdentifier content =
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
    = None



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    ( model, Cmd.none )



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
