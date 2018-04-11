module Issue
    exposing
        ( Id(..)
        , Issue
        , decoder
        , details
        , extractId
        , isChargeable
        , name
        , requiresComponent
        , sameId
        , setDetails
        , setSubject
        , subject
        , supportType
        )

import Json.Decode as D
import SelectList exposing (SelectList)
import SelectList.Extra
import SupportType exposing (SupportType(..))
import Tier exposing (Tier)
import Utils


type Issue
    = ComponentRequiredIssue IssueData
    | StandardIssue IssueData


type alias IssueData =
    { id : Id
    , name : String
    , details : String
    , subject : String
    , supportType : SupportType
    , chargeable : Bool
    , tiers : SelectList Tier
    }


type Id
    = Id Int


decoder : D.Decoder Issue
decoder =
    let
        createIssue =
            \id ->
                \name ->
                    \requiresComponent ->
                        \detailsTemplate ->
                            \defaultSubject ->
                                \supportType ->
                                    \chargeable ->
                                        \tiers ->
                                            let
                                                data =
                                                    IssueData
                                                        id
                                                        name
                                                        detailsTemplate
                                                        defaultSubject
                                                        supportType
                                                        chargeable
                                                        tiers
                                            in
                                            if requiresComponent then
                                                ComponentRequiredIssue data
                                            else
                                                StandardIssue data
    in
    D.map8 createIssue
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
        (D.field "detailsTemplate" D.string)
        (D.field "defaultSubject" D.string)
        (D.field "supportType" SupportType.decoder)
        (D.field "chargeable" D.bool)
        (D.field "tiers" <| SelectList.Extra.orderedDecoder Tier.levelAsInt Tier.decoder)


extractId : Issue -> Int
extractId issue =
    case data issue |> .id of
        Id id ->
            id


requiresComponent : Issue -> Bool
requiresComponent issue =
    case issue of
        ComponentRequiredIssue _ ->
            True

        StandardIssue _ ->
            False


name : Issue -> String
name issue =
    data issue |> .name


details : Issue -> String
details issue =
    data issue |> .details


subject : Issue -> String
subject issue =
    data issue |> .subject


setDetails : String -> Issue -> Issue
setDetails details =
    updateIssueData (\data -> { data | details = details })


setSubject : String -> Issue -> Issue
setSubject subject =
    updateIssueData (\data -> { data | subject = subject })


updateIssueData : (IssueData -> IssueData) -> Issue -> Issue
updateIssueData changeData issue =
    let
        newData =
            data issue |> changeData
    in
    case issue of
        ComponentRequiredIssue _ ->
            ComponentRequiredIssue newData

        StandardIssue _ ->
            StandardIssue newData


supportType : Issue -> SupportType
supportType issue =
    data issue |> .supportType


isChargeable : Issue -> Bool
isChargeable issue =
    data issue |> .chargeable


data : Issue -> IssueData
data issue =
    case issue of
        ComponentRequiredIssue data ->
            data

        StandardIssue data ->
            data


sameId : Id -> Issue -> Bool
sameId id issue =
    data issue |> Utils.sameId id
