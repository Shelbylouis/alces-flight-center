
# Concern to hold shared behaviour for anything which belongs to a cluster,
# either directly or through other relations.
module BelongsToCluster
  extend ActiveSupport::Concern

  def namespaced_name
    if cluster
      "#{name} (#{cluster.name})"
    else
      name
    end
  end
end
