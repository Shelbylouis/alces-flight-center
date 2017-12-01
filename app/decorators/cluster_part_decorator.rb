class ClusterPartDecorator < ApplicationDecorator
  delegate_all
  decorates_association :cluster

  def links
    self_link = h.link_to name, path
    h.raw("#{self_link} (#{cluster.links})")
  end
end
