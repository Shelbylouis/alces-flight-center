module Main exposing (..)

import Html exposing (Html)
import Json.Decode as D
import Msg exposing (..)
import State exposing (State)
import State.Update
import State.View
import View.Utils
import Maybe
import Result
import List


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
    let
        model = decodeInitialModel flags

        mmsgs = [
            maybeToolMessage ChangeSelectedIssue "selectedIssue" flags,
            maybeToolMessage ChangeSelectedCategory "selectedCategory" flags
        ]

        updateCollectingCmds mmsg (m1, cs1) =
            case mmsg of
                Just msg ->
                    let
                        (m2, cs2) = update msg m1
                    in
                        (m2 ! [cs1, cs2])
                Nothing -> (m1 ! [cs1])
    in
        List.foldr updateCollectingCmds (model ! []) mmsgs


maybeToolMessage : (String -> msg) -> String -> D.Value -> Maybe msg
maybeToolMessage msg fieldName flags =
    let
        getFieldId : Maybe String
        getFieldId =
            case decodeField of
                Result.Ok v -> v
                Result.Err e -> Nothing

        decodeField : Result String (Maybe String)
        decodeField =
            D.decodeValue (D.maybe (D.field fieldName D.string)) flags

    in
        Maybe.map msg getFieldId


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
