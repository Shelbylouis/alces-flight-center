class ClusterDecorator < ApplicationDecorator
  delegate_all
  decorates_association :component_groups
  decorates_association :services

  alias :case_form_buttons :cluster_part_case_form_buttons

  def path
    h.cluster_path(self)
  end

  def links
    h.link_to name, path
  end
end
