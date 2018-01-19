class AssetRecordsController < ApplicationController
  def edit
    @asset = asset
    @title = "Edit Asset Record"
  end

  def update
    redirect_to asset
  end

  private

  def asset
    @cluster_part || @component_group
  end
end
