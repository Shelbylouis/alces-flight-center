class ComponentGroupsController < ApplicationController
  decorates_assigned :component_group

  # There is no "show" ComponentGroup page anymore. Instead the asset_record
  # is the landing page. The action has been maintained to prevent changes
  # to the public API
  def show
    render 'asset_records/show'
  end
end
