
# Concern to hold shared behaviour for anything which belongs to a cluster,
# either directly or through other relations.
module BelongsToCluster
  extend ActiveSupport::Concern

  def namespaced_name
    "#{name} (#{cluster.name})"
  end
end
