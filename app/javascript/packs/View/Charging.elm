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
                _Credit allocation to issues is based on total time spent on
                the issue by our engineers:_

                0 to 30m - 0 Credits

                30m to 3h - 1 Credits

                3h to 6h - 2 Credits

                6h to 9h - 3 Credits

                9h to 12h - 4 Credits

                &gt; 12h - 5 Credits
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
    resolve your issue. Click here for the credit usage details
    for this cluster."""
