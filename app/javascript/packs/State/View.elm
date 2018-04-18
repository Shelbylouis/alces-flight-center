module State.View exposing (view)

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onSubmit)
import Issue exposing (Issue)
import Maybe.Extra
import Msg exposing (..)
import SelectList
import State exposing (State)
import View.CaseForm as CaseForm
import View.Utils


-- XXX Refactor functions in here and in `View.*` modules to use
-- `elm-bootstrap`.


view : State -> Html Msg
view state =
    div [ class "case-form" ]
        (Maybe.Extra.values
            [ chargingInfoModal state |> Just
            , chargeableIssuePreSubmissionModal state |> Just
            , State.selectedIssue state |> chargeableIssueAlert
            , submitErrorAlert state
            , CaseForm.view state |> Just
            ]
        )


chargingInfoModal : State -> Html Msg
chargingInfoModal state =
    let
        cluster =
            SelectList.selected state.clusters

        chargingInfo =
            cluster.chargingInfo
                |> Maybe.map text
                |> Maybe.withDefault noChargingInfoAvailable

        noChargingInfoAvailable =
            span []
                [ text "No charging info has been provided by Alces Software for "
                , strong [] [ text cluster.name ]
                , text "; if you require clarification on what charges you may incur please contact "
                , View.Utils.supportEmailLink
                , text "."
                ]
    in
    Modal.config ClusterChargingInfoModal
        |> Modal.h5 [] [ cluster.name ++ " charging info" |> text ]
        |> Modal.body [] [ chargingInfo ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs
                    [ ClusterChargingInfoModal Modal.hiddenState |> onClick ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view state.clusterChargingInfoModal


chargeableIssuePreSubmissionModal : State -> Html Msg
chargeableIssuePreSubmissionModal state =
    let
        bodyContent =
            [ p []
                [ text "The selected issue ("
                , em [] [ State.selectedIssue state |> Issue.name |> text ]
                , text ") is chargeable, and creating this support case may incur a support credit charge."
                ]
            , p [] [ text "Do you wish to continue?" ]
            ]
    in
    Modal.config ChargeableIssuePreSubmissionModal
        |> Modal.h5 [] [ text "This support case may incur charges" ]
        |> Modal.body [] bodyContent
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs
                    [ ChargeableIssuePreSubmissionModal Modal.hiddenState |> onClick ]
                ]
                [ text "Cancel" ]
            , Button.button
                [ Button.outlineWarning
                , Button.attrs
                    [ onClick StartSubmit ]
                ]
                [ text "Create Case" ]
            ]
        |> Modal.view state.chargeableIssuePreSubmissionModal


submitErrorAlert : State -> Maybe (Html Msg)
submitErrorAlert state =
    -- This closely matches the error alert we show from Rails, but is managed
    -- by Elm rather than Bootstrap JS.
    let
        displayError =
            \error ->
                Alert.danger
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


chargeableIssueAlert : Issue -> Maybe (Html Msg)
chargeableIssueAlert issue =
    let
        dollar =
            span [ class "fa fa-dollar" ] []

        chargingInfo =
            " This issue is chargeable and may incur a charge of support credits. "

        clusterChargingInfoLinkText =
            "Click here for the charging details for this cluster."
    in
    if Issue.isChargeable issue then
        Alert.warning
            [ dollar
            , dollar
            , dollar
            , text chargingInfo
            , Alert.link
                [ ClusterChargingInfoModal Modal.visibleState |> onClick

                -- This makes this display as a normal link, but clicking on it
                -- not reload the page. There may be a better way to do this;
                -- `href="#"` does not work.
                , href "javascript:void(0)"
                ]
                [ text clusterChargingInfoLinkText ]
            ]
            |> Just
    else
        Nothing
