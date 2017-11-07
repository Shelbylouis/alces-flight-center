module Issue
    exposing
        ( Id(..)
        , Issue
        , availableForSelectedCluster
        , decoder
        , details
        , detailsValid
        , extractId
        , name
        , requiresComponent
        , requiresService
        , sameId
        , setDetails
        , supportType
        )

import Cluster exposing (Cluster)
import Json.Decode as D
import SelectList exposing (SelectList)
import ServiceType exposing (ServiceType)
import SupportType exposing (SupportType(..))
import Utils


type Issue
    = ComponentRequiredIssue IssueData
    | ServiceRequiredIssue IssueData
    | SpecificServiceRequiredIssue ServiceType IssueData
    | StandardIssue IssueData


type alias IssueData =
    { id : Id
    , name : String
    , details : String
    , supportType : SupportType
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
                        \requiresService ->
                            \detailsTemplate ->
                                \supportType ->
                                    \serviceType ->
                                        let
                                            data =
                                                IssueData id name detailsTemplate supportType
                                        in
                                        if requiresComponent then
                                            ComponentRequiredIssue data
                                        else if requiresService then
                                            case serviceType of
                                                Just type_ ->
                                                    SpecificServiceRequiredIssue type_ data

                                                Nothing ->
                                                    ServiceRequiredIssue data
                                        else
                                            StandardIssue data
    in
    D.map7 createIssue
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
        (D.field "requiresService" D.bool)
        (D.field "detailsTemplate" D.string)
        (D.field "supportType" SupportType.decoder)
        (D.field "serviceType" (D.nullable ServiceType.decoder))


detailsValid : Issue -> Bool
detailsValid issue =
    details issue |> String.isEmpty |> not


availableForSelectedCluster : SelectList Cluster -> Issue -> Bool
availableForSelectedCluster clusters issue =
    let
        issueIsManaged =
            data issue |> SupportType.isManaged

        clusterIsAdvice =
            SelectList.selected clusters
                |> SupportType.isAdvice
    in
    -- An Issue is available so long as it is not a managed issue while an
    -- advice-only Cluster is selected.
    not (issueIsManaged && clusterIsAdvice)


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

        ServiceRequiredIssue _ ->
            False

        SpecificServiceRequiredIssue _ _ ->
            False

        StandardIssue _ ->
            False


requiresService : Issue -> Bool
requiresService issue =
    case issue of
        ComponentRequiredIssue _ ->
            False

        ServiceRequiredIssue _ ->
            True

        SpecificServiceRequiredIssue _ _ ->
            True

        StandardIssue _ ->
            False


name : Issue -> String
name issue =
    data issue |> .name


details : Issue -> String
details issue =
    data issue |> .details


setDetails : Issue -> String -> Issue
setDetails issue details =
    let
        data_ =
            data issue

        newData =
            { data_ | details = details }
    in
    case issue of
        ComponentRequiredIssue _ ->
            ComponentRequiredIssue newData

        ServiceRequiredIssue _ ->
            ServiceRequiredIssue newData

        SpecificServiceRequiredIssue type_ _ ->
            SpecificServiceRequiredIssue type_ newData

        StandardIssue _ ->
            StandardIssue newData


supportType : Issue -> SupportType
supportType issue =
    data issue |> .supportType


data : Issue -> IssueData
data issue =
    case issue of
        ComponentRequiredIssue data ->
            data

        ServiceRequiredIssue data ->
            data

        SpecificServiceRequiredIssue _ data ->
            data

        StandardIssue data ->
            data


sameId : Id -> Issue -> Bool
sameId id issue =
    data issue |> Utils.sameId id
