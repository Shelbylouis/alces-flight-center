class CreateCreditDeposits < ActiveRecord::Migration[5.1]
  def change
    create_table :credit_deposits do |t|
      t.timestamps null: false

      t.references :cluster, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false
      t.integer :amount, null: false
    end
  end
end
