class ClusterDecorator < ApplicationDecorator
  delegate_all
  decorates_association :component_groups
  decorates_association :services

  def path
    h.cluster_path(self)
  end

  def links
    h.link_to name, path
  end
end
