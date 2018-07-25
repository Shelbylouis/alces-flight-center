class AddEffectiveDateToCreditDeposits < ActiveRecord::Migration[5.2]
  def change
    add_column :credit_deposits, :effective_date, :date
  end
end
