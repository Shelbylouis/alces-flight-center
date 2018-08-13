class DeleteAuditsCausedByMigration < ActiveRecord::Migration[5.2]
  def up
    # These audits were created by the SetNewCaseAssociations migration.
    # They're harmless - the funky associated_type means they're never going to
    # be used by anything - but no need to have them lying around in the database
    # taking up space.
    Audited::Audit.where(associated_type: 'SetNewCaseAssociations::Case').delete_all
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
