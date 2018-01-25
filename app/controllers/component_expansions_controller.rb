class ComponentExpansionsController < ApplicationController
  def update
    redirect_to @cluster_part
  end

  def edit
    @title = "Edit Expansions"
    @subtitle = @cluster_part.name
  end
end
