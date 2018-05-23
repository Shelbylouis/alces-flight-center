class RemoveLegacyCreditChargeModels < ActiveRecord::Migration[5.1]
  def up
    drop_table :credit_charges
    drop_table :credit_deposits
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
