class ClustersController < ApplicationController
  decorates_assigned :cluster

  def show
    @cluster = Cluster.includes(
      components: [:maintenance_windows],
      services: [:maintenance_windows]
    ).find(params[:id])

    @title = "#{@cluster.name} Management Dashboard"

    support_type = case @cluster.support_type.to_sym
                   when :managed
                     'Managed'
                   when :advice
                     'Self-managed'
                   end
    @subtitle = "#{support_type} cluster"
  end
end
