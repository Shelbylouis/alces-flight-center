class RenameArchivedToClosed < ActiveRecord::DataMigration
  def up
    Case.where(state: 'archived').each do |kase|
      # NB By setting `state` directly we avoid generating any CaseStateTransitions
      kase.state = 'closed'
      kase.save!
    end
  end
end
