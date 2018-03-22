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

  def tabs
    [
      tabs_builder.overview,
      { id: :logs, path: h.cluster_logs_path(self) },
      tabs_builder.cases,
      {
        id: :maintenance,
        path: h.cluster_maintenance_windows_path(self),
        admin_dropdown: [
          {
            text: 'Existing',
            path: h.cluster_maintenance_windows_path(self)
          }, {
            text: 'Request',
            path: h.new_cluster_maintenance_window_path(self)
          }
        ]
      },
      { id: :services, path: h.cluster_services_path(self) },
      {
        id: :components, path: '', # Path is ignored b/c dropdown
        dropdown: self.component_groups_by_type.map(&:name).map do |t|
          { text: t, path: h.cluster_components_path(self, type: t) }
        end.push(text: 'All', path: h.cluster_components_path(self))
      }
    ]
  end
end
