class SetNewCaseAssociations < ActiveRecord::Migration[5.2]

  class Case < ApplicationRecord
    # Minimal set of relationships required for this migration to function.
    # Note that the belongs_to relationships are deleted in the model so must
    # be specified here.
    belongs_to :service, required: false
    belongs_to :component, required: false

    has_many :case_associations
    has_many :services,
             through: :case_associations,
             source: :associated_element,
             source_type: 'Service'

    has_many :components,
             through: :case_associations,
             source: :associated_element,
             source_type: 'Component'

  end

  def up
    Case.all.each do |kase|

      if kase.service.present?
        kase.services << kase.service unless kase.services.include? kase.service
      end

      if kase.component.present?
        kase.components << kase.component unless kase.components.include? kase.component
      end

      # NB Not previously possible to associate a ComponentGroup so no data to
      # migrate

    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
