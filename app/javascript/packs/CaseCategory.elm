module CaseCategory exposing (..)

import Issue exposing (Issue)
import Json.Decode as D
import SelectList exposing (SelectList)
import Utils


type alias CaseCategory =
    { id : Id
    , name : String
    , issues : SelectList Issue
    }


type Id
    = Id Int


decoder : D.Decoder CaseCategory
decoder =
    D.map3 CaseCategory
        (D.field "id" D.int |> D.map Id)
        (D.field "name" D.string)
        (D.field "issues" (Utils.selectListDecoder Issue.decoder))
