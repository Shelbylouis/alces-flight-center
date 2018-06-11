class MigrateLegacyCaseCharges < ActiveRecord::Migration[5.2]
  def up
    Case.where(state: 'closed').each do |k|
      unless k.credit_charge.present?
        k.create_credit_charge(amount: k.legacy_credit_charge)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
