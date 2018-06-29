class SetNewCaseAssociations < ActiveRecord::Migration[5.2]
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
