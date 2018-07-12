class MigrateLegacyMwAssociations < ActiveRecord::Migration[5.2]

  class MaintenanceWindow < ApplicationRecord
    # Minimal set of relationships required for this migration to function.
    belongs_to :service, required: false
    belongs_to :component, required: false
    belongs_to :cluster, required: false

    has_many :maintenance_window_associations
    has_many :services,
             through: :maintenance_window_associations,
             source: :associated_element,
             source_type: 'Service'

    has_many :components,
             through: :maintenance_window_associations,
             source: :associated_element,
             source_type: 'Component'

    has_many :clusters,
             through: :maintenance_window_associations,
             source: :associated_element,
             source_type: 'Cluster'
  end

  def up
    MaintenanceWindow.all.each do |mw|
      mw.services << mw.service if mw.service.present? && !mw.services.include?(mw.service)
      mw.components << mw.component if mw.component.present? && !mw.components.include?(mw.component)
      mw.clusters << mw.cluster if mw.cluster.present? && !mw.clusters.include?(mw.cluster)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
