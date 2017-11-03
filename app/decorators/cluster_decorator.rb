class ClusterDecorator < ApplicationDecorator
  delegate_all
  decorates_association :component_groups
  decorates_association :services

  def path
    h.cluster_path(self)
  end
end
