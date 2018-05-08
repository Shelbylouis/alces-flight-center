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

  def tabs
    [
      tabs_builder.overview,
      tabs_builder.logs,
      tabs_builder.cases,
      {
        id: :maintenance,
        path: h.cluster_maintenance_windows_path(self),
        admin_dropdown: [
          {
            text: 'Pending',
            path: h.cluster_maintenance_windows_path(self)
          }, {
            text: 'Request',
            path: h.new_cluster_maintenance_window_path(self)
          }
        ]
      },
      { id: :services, path: h.cluster_services_path(self) },
      {
        id: :components,
        dropdown: self.component_groups_by_type.map(&:name).map do |t|
          {
            text: t.pluralize,
            path: h.cluster_components_path(self, type: t)
          }
        end.push(text: 'All', path: h.cluster_components_path(self))
      }
    ]
  end
end
