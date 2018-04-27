module Main exposing (..)

import Html exposing (Html)
import Json.Decode as D
import Msg exposing (..)
import State exposing (State)
import State.Update
import State.View
import View.Utils


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
    decodeInitialModel flags ! []



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        Initialized state ->
            State.View.view state

        Error message ->
            Html.span []
                [ Html.text
                    ("Error initializing form: "
                        ++ message
                        ++ ". Please contact "
                    )
                , View.Utils.supportEmailLink
                , Html.text "."
                ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Initialized state ->
            let
                ( newState, cmd ) =
                    State.Update.update msg state
                        |> Maybe.withDefault (state ! [])
            in
            ( Initialized newState, cmd )

        Error message ->
            model ! []



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
