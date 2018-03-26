class ClustersController < ApplicationController
  decorates_assigned :cluster

  def show
    @cluster = Cluster.find(params[:id])

    support_type = case @cluster.support_type.to_sym
                   when :managed
                     'Managed'
                   when :advice
                     'Self-managed'
                   end
    @subtitle = "#{support_type} cluster"
  end
end
