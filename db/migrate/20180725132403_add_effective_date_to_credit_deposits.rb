class AddEffectiveDateToCreditDeposits < ActiveRecord::Migration[5.2]
  def change
    add_column :credit_deposits, :effective_date, :date
    add_index :credit_deposits, :effective_date
  end
end
