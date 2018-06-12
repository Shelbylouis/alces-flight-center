class MigrateLegacyCaseCharges < ActiveRecord::Migration[5.2]
  def up
    Case.where(state: 'closed').each do |k|
      unless k.credit_charge.present?

        # If a Case is closed, it ought to have a transition to that state!
        closing_user = k.transitions.find_by(to: 'closed').user

        k.create_credit_charge!(amount: k.legacy_credit_charge, user: closing_user)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
