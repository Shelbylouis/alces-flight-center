module Issue
    exposing
        ( Id(..)
        , Issue
        , decoder
        , extractId
        , isChargeable
        , name
        , requiresComponent
        , sameId
        , selectTier
        , setSubject
        , subject
        , tiers
        , updateSelectedTierField
        )

import Json.Decode as D
import SelectList exposing (SelectList)
import SelectList.Extra
import Tier exposing (Tier)
import Utils


type Issue
    = ComponentRequiredIssue IssueData
    | StandardIssue IssueData


type alias IssueData =
    { id : Id
    , name : String
    , subject : String
    , chargeable : Bool
    , tiers : SelectList Tier
    }


type Id
    = Id Int


decoder : D.Decoder Issue
decoder =
    let
        createIssue =
            \id name requiresComponent defaultSubject chargeable tiers ->
                let
                    data =
                        IssueData
                            id
                            name
                            defaultSubject
                            chargeable
                            tiers
                in
                if requiresComponent then
                    ComponentRequiredIssue data
                else
                    StandardIssue data
    in
    D.map6 createIssue
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
        (D.field "defaultSubject" D.string)
        (D.field "chargeable" D.bool)
        (D.field "tiers" <|
            SelectList.Extra.orderedDecoder
                (.level >> Tier.levelAsInt)
                Tier.decoder
        )


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


subject : Issue -> String
subject issue =
    data issue |> .subject


tiers : Issue -> SelectList Tier
tiers issue =
    data issue |> .tiers


setSubject : String -> Issue -> Issue
setSubject subject =
    updateIssueData (\data -> { data | subject = subject })


selectTier : Tier.Id -> Issue -> Issue
selectTier tierId issue =
    updateIssueData
        (\data ->
            { data
                | tiers = SelectList.select (Utils.sameId tierId) (tiers issue)
            }
        )
        issue


updateSelectedTierField : Int -> String -> Issue -> Issue
updateSelectedTierField fieldIndex value issue =
    updateIssueData
        (\data ->
            { data
                | tiers =
                    SelectList.Extra.mapSelected
                        (\tier -> Tier.setFieldValue tier fieldIndex value)
                        data.tiers
            }
        )
        issue


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
