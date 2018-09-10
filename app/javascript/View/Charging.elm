module View.Charging
    exposing
        ( chargeableAlert
        , chargeablePreSubmissionModal
        , infoModal
        )

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Markdown
import Msg exposing (..)
import State exposing (State)
import String.Extra
import Tier


chargeableAlert : State -> Maybe (Html Msg)
chargeableAlert state =
    let
        isChargeable =
            Tier.isChargeable <| State.selectedTier state

        alertChildren =
            List.intersperse (text " ")
                [ dollars
                , potentiallyChargeableText
                , chargingInfoModalLink
                ]

        dollars =
            span [] (List.repeat 3 dollar)

        dollar =
            span [ class "fa fa-dollar" ] []

        chargingInfoModalLink =
            Alert.link
                [ ClusterChargingInfoModal Modal.shown |> onClick

                -- Make this display as a normal link, but clicking on it not
                -- reload the page.
                , href "javascript:void(0)"
                ]
                [ text "Click here for the charging details for this cluster." ]
    in
    if isChargeable then
        Just <|
            Alert.simpleWarning
                [ Spacing.mt2, Spacing.mb0 ]
                alertChildren
    else
        Nothing


infoModal : State -> Html Msg
infoModal state =
    let
        cluster =
            State.selectedCluster state

        chargingInfo =
            cluster.chargingInfo
                |> Maybe.withDefault defaultChargingInfoText
                |> Markdown.toHtml []

        defaultChargingInfoText =
            -- Default charging info provided by Steve (at
            -- https://alces.slack.com/archives/C72GT476Y/p1526552123000289);
            -- if we regularly need to change this we should move it from being
            -- embedded within the app.
            String.Extra.unindent """
                *Credit allocation to cases is based on the total time worked by our engineers:*

                * 0 to 30 minutes ➝ **0** credits

                * 30 minutes to 3 hours ➝ **1** credit

                * 3 to 6 hours ➝ **2** credits

                * 6 to 9 hours ➝ **3** credits

                * 9 to 12 hours ➝ **4** credits

                * Over 12 hours ➝ **5** credits

                *Note that time worked is measured in business (not elapsed) hours.*
            """
    in
    Modal.config (ClusterChargingInfoModal Modal.hidden)
        |> Modal.h5 [] [ cluster.name ++ " charging info" |> text ]
        |> Modal.body [] [ chargingInfo ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs
                    [ ClusterChargingInfoModal Modal.hidden |> onClick ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view state.clusterChargingInfoModal


chargeablePreSubmissionModal : State -> Html Msg
chargeablePreSubmissionModal state =
    let
        bodyContent =
            [ p [] [ potentiallyChargeableText ]
            , p [] [ text "Do you wish to continue?" ]
            ]
    in
    Modal.config (ChargeablePreSubmissionModal Modal.hidden)
        |> Modal.h5 [] [ text "Please note" ]
        |> Modal.body [] bodyContent
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs
                    [ ChargeablePreSubmissionModal Modal.hidden |> onClick ]
                ]
                [ text "Cancel" ]
            , Button.button
                [ Button.outlineWarning
                , Button.attrs
                    [ onClick StartSubmit ]
                ]
                [ text "Create Case" ]
            ]
        |> Modal.view state.chargeablePreSubmissionModal


potentiallyChargeableText : Html Msg
potentiallyChargeableText =
    text """Creating a support case at this tier means that you
    authorise potential use of available account credit to help
    resolve your issue."""
