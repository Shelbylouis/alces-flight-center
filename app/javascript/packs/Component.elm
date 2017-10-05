module Component exposing (..)

import Cluster
import Json.Decode as D


type alias Component =
    { id : Id
    , name : String
    , clusterId : Cluster.Id
    }


type Id
    = Id Int


forCluster : Cluster.Id -> List Component -> List Component
forCluster clusterId components =
    let
        partOfCluster =
            \component ->
                component.clusterId == clusterId
    in
    List.filter partOfCluster components


decoder : D.Decoder Component
decoder =
    D.map3 Component
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "clusterId" D.int |> D.map Cluster.Id)
