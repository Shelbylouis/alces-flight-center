module View.Charging
    exposing
        ( chargeableAlert
        , chargeablePreSubmissionModal
        , infoModal
        )

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Msg exposing (..)
import SelectList
import State exposing (State)
import Tier
import View.Utils


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

                -- This makes this display as a normal link, but clicking on it
                -- not reload the page. There may be a better way to do this;
                -- `href="#"` does not work.
                , href "javascript:void(0)"
                ]
                [ text "Click here for the charging details for this cluster." ]
    in
    if isChargeable then
        Just <| Alert.simpleWarning [] alertChildren
    else
        Nothing


infoModal : State -> Html Msg
infoModal state =
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
        |> Modal.h5 [] [ text "This support case may incur charges" ]
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
    text """Creating a support case at this tier is potentially
    chargeable, and may incur a charge of support credits."""
