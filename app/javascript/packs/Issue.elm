module Issue
    exposing
        ( Id(..)
        , Issue
        , availableForSelectedCluster
        , decoder
        , details
        , detailsValid
        , extractId
        , isChargeable
        , name
        , requiresComponent
        , requiresService
        , sameId
        , serviceAllowedFor
        , serviceCanBeAssociatedWith
        , serviceRequired
        , setDetails
        , supportType
        )

import Cluster exposing (Cluster)
import Json.Decode as D
import SelectList exposing (SelectList)
import Service exposing (Service)
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
    , chargeable : Bool
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
                                        \chargeable ->
                                            let
                                                data =
                                                    IssueData id name detailsTemplate supportType chargeable
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
    D.map8 createIssue
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
        (D.field "requiresService" D.bool)
        (D.field "detailsTemplate" D.string)
        (D.field "supportType" SupportType.decoder)
        (D.field "serviceType" (D.nullable ServiceType.decoder))
        (D.field "chargeable" D.bool)


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
    case serviceRequired issue of
        ServiceType.None ->
            False

        _ ->
            True


serviceRequired : Issue -> ServiceType.ServiceRequired
serviceRequired issue =
    case issue of
        ComponentRequiredIssue _ ->
            ServiceType.None

        ServiceRequiredIssue _ ->
            ServiceType.Any

        SpecificServiceRequiredIssue type_ _ ->
            ServiceType.SpecificType type_

        StandardIssue _ ->
            ServiceType.None


{-|

    Whether given Service can be selected along with given Issue. Returns True
    either when this Service can be associated with this Issue, or Issue does
    not require a Service (so it doesn't matter which is selected).

-}
serviceAllowedFor : Issue -> Service -> Bool
serviceAllowedFor issue service =
    if serviceRequired issue == ServiceType.None then
        True
    else
        serviceCanBeAssociatedWith service issue


{-|

    Whether given Service can be associated with given Issue. Returns True iff
    Issue requires Service and Service is correct type.

-}
serviceCanBeAssociatedWith : Service -> Issue -> Bool
serviceCanBeAssociatedWith service issue =
    case serviceRequired issue of
        ServiceType.None ->
            -- Issue does not require a Service.
            False

        ServiceType.SpecificType serviceType ->
            -- Service is allowed iff has ServiceType that Issue requires.
            Utils.sameId serviceType.id service.serviceType

        ServiceType.Any ->
            -- Issue takes any Service.
            True


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


isChargeable : Issue -> Bool
isChargeable issue =
    data issue |> .chargeable


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
