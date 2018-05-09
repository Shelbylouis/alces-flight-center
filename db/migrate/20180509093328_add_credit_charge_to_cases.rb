class AddCreditChargeToCases < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :credit_charge, :integer, null: true, default: nil
  end
end
