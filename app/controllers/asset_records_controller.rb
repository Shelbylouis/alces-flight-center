class AssetRecordsController < ApplicationController
  def edit
    @title = "Title"
    @subtitle = "Subtitle"
    asset
  end

  private

  VALID_ASSET_IDS = [:component_id, :component_group_id]

  def asset
    ensure_single_asset_only
  end

  def ensure_single_asset_only
    (asset_params.keys & VALID_ASSET_IDS.map(&:to_s)).tap do |ids|
      raise 'Can not determine asset' unless ids.length == 1
    end
  end

  def asset_params
    params.permit(*VALID_ASSET_IDS)
  end
end
