
module BelongsToCluster
  extend ActiveSupport::Concern

  def namespaced_name
    "#{name} (#{cluster.name})"
  end
end
