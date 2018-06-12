class MigrateLegacyCaseCharges < ActiveRecord::Migration[5.2]
  def up
    Case.where(state: 'closed').each do |k|
      unless k.credit_charge.present?

        audits = k.audits.where(action: 'update').all

        charge_audit = audits.select { |audit|
          audit.audited_changes.include? 'credit_charge'
        }.last

        k.create_credit_charge!(
          amount: k.legacy_credit_charge,
          user: charge_audit.user,
          created_at: charge_audit.created_at
        )

        # We want to delete the original audit because:
        #  - all its relevant information is now captured in CreditCharge;
        #  - if we don't then duplicate "charge added" entries may appear in
        #    a Case's events feed even though the charge only gets added once
        charge_audit.delete
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
