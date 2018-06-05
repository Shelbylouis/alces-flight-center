class ClusterDecorator < ApplicationDecorator
  delegate_all
  decorates_association :components
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
      documents.empty? ? nil : { id: :documents, path: h.cluster_documents_path(self) },
      tabs_builder.logs,
      tabs_builder.cases,
      tabs_builder.maintenance,
      { id: :services, path: h.cluster_services_path(self) },
      {
        id: :components,
        dropdown: self.available_component_group_types.map do |t|
          {
            text: t.pluralize,
            path: h.cluster_components_path(self, type: t)
          }
        end.push(text: 'All', path: h.cluster_components_path(self))
      },
      notes_tab,
    ].compact
  end

  def case_form_json
    {
      id: id,
      name: name,
      components: components.map(&:case_form_json),
      services: services.map(&:case_form_json),
      supportType: support_type,
      chargingInfo: charging_info,
      # Encode MOTD in two forms: the raw form, to be used as the initial value
      # to be edited in the MOTD tool, and as sanitized, formatted HTML so the
      # current value can be displayed as it will be on the Cluster and in the
      # rest of Flight Center.
      motd: motd,
      motdHtml: h.simple_format(motd),
    }
  end

  private

  def notes_tab
    if current_user.admin?
      {
        id: :notes,
        dropdown: [
          {
            text: 'Engineering',
            path: h.engineering_cluster_notes_path(self),
          },
          {
            text: 'Customer',
            path: h.customer_cluster_notes_path(self),
          },
        ]
      }
    else
      {
        id: :notes,
        path: h.customer_cluster_notes_path(self),
      }
    end
  end
end
