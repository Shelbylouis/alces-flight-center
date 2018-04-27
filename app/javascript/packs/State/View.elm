module State.View exposing (view)

import Bootstrap.Alert as Alert
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Maybe.Extra
import Msg exposing (..)
import State exposing (State)
import View.CaseForm as CaseForm
import View.Charging as Charging


-- XXX Refactor functions in here and in `View.*` modules to use
-- `elm-bootstrap`.


view : State -> Html Msg
view state =
    div [ class "case-form" ]
        (Maybe.Extra.values
            [ Charging.infoModal state |> Just
            , Charging.chargeablePreSubmissionModal state |> Just
            , submitErrorAlert state
            , CaseForm.view state |> Just
            ]
        )


submitErrorAlert : State -> Maybe (Html Msg)
submitErrorAlert state =
    -- This closely matches the error alert we show from Rails, but is managed
    -- by Elm rather than Bootstrap JS.
    let
        displayError =
            \error ->
                -- XXX Update this to use new `Alert.dismissable` or
                -- `Alert/dismissableWithAnimation` function from
                -- elm-bootstrap, rather than handling dismissing ourselves.
                Alert.simpleDanger
                    []
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
