class RemoveLegacyCreditChargeFromCases < ActiveRecord::Migration[5.2]
  def change
    remove_column :cases, :legacy_credit_charge, :integer
  end
end
