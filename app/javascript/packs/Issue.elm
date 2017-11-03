module Issue exposing (..)

import Cluster exposing (Cluster)
import Json.Decode as D
import SelectList exposing (SelectList)
import SupportType exposing (SupportType(..))


type alias Issue =
    { id : Id
    , name : String
    , requiresComponent : Bool
    , requiresService : Bool
    , details : String
    , supportType : SupportType
    }


type Id
    = Id Int


decoder : D.Decoder Issue
decoder =
    D.map6 Issue
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "requiresComponent" D.bool)
        (D.field "requiresService" D.bool)
        (D.field "detailsTemplate" D.string)
        (D.field "supportType" SupportType.decoder)


detailsValid : Issue -> Bool
detailsValid issue =
    String.isEmpty issue.details |> not


availableForSelectedCluster : SelectList Cluster -> Issue -> Bool
availableForSelectedCluster clusters issue =
    let
        issueIsManaged =
            SupportType.isManaged issue

        clusterIsAdvice =
            SelectList.selected clusters
                |> SupportType.isAdvice
    in
    -- An Issue is available so long as it is not a managed issue while an
    -- advice-only Cluster is selected.
    not (issueIsManaged && clusterIsAdvice)


extractId : Issue -> Int
extractId issue =
    case issue.id of
        Id id ->
            id
