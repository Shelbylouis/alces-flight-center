module Issue
    exposing
        ( Id(..)
        , Issue
        , extractId
        , findTier
        , id
        , issuesDecoder
        , name
        , requiresComponent
        , sameId
        , selectTier
        , setSubject
        , subject
        , tiers
        , updateSelectedTierField
        )

import DrillDownSelectList exposing (DrillDownSelectList)
import Json.Decode as D
import SelectList exposing (SelectList)
import SelectList.Extra
import Tier exposing (Tier)
import Tier.Level
import Utils


type Issue
    = ComponentRequiredIssue IssueData
    | StandardIssue IssueData


type alias IssueData =
    { id : Id
    , name : String
    , subject : String
    , tiers : SelectList Tier
    }


type Id
    = Id Int


issuesDecoder : String -> D.Decoder (DrillDownSelectList Issue)
issuesDecoder clusterMotd =
    let
        issueDecoder =
            decoder clusterMotd
    in
    DrillDownSelectList.orderedDecoder name issueDecoder


decoder : String -> D.Decoder Issue
decoder clusterMotd =
    let
        createIssue =
            \id name requiresComponent defaultSubject tiers ->
                let
                    data =
                        IssueData
                            id
                            name
                            defaultSubject
                            tiers
                in
                if requiresComponent then
                    ComponentRequiredIssue data
                else
                    StandardIssue data
    in
    D.map5 createIssue
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
        (D.field "defaultSubject" D.string)
        (D.field "tiers" <|
            SelectList.Extra.orderedDecoder
                (.level >> Tier.Level.asInt)
                (Tier.decoder clusterMotd)
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


id : Issue -> Id
id issue =
    data issue |> .id


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


findTier : (Tier -> Bool) -> Issue -> Maybe Tier
findTier predicate issue =
    SelectList.Extra.find predicate (issue |> data |> .tiers)
