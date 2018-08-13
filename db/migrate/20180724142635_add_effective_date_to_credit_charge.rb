class AddEffectiveDateToCreditCharge < ActiveRecord::Migration[5.2]
  def change
    add_column :credit_charges, :effective_date, :date
    add_index :credit_charges, :effective_date
  end
end
