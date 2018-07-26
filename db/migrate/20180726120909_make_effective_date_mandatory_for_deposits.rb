class MakeEffectiveDateMandatoryForDeposits < ActiveRecord::Migration[5.2]
  def change
    change_column_null :credit_deposits, :effective_date, false
  end
end
