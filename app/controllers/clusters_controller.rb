class ClustersController < ApplicationController
  def show
    @cluster = Cluster.find(params[:id])
    @title = "#{@cluster.name} Management Dashboard"

    support_type = case @cluster.support_type.to_sym
                   when :managed
                     'Managed'
                   when :advice
                     'Self-managed'
                   end
    @subtitle = "#{support_type} cluster"
    # @cluster.description
  end
end
