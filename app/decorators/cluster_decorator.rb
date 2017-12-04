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

  def case_form_buttons
    buttons = [
      case_form_button(h.new_cluster_case_path(cluster_id: self.id)),
      consultancy_form_button(h.new_cluster_consultancy_path(cluster_id: self.id))
    ].join
    h.raw(buttons)
  end
end
