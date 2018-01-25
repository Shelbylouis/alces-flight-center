class ComponentExpansionsController < ApplicationController
  def edit
    @title = "Edit Expansions"
    @subtitle = @cluster_part.name
  end
end
