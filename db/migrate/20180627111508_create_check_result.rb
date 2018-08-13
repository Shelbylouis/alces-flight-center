class CreateCheckResult < ActiveRecord::Migration[5.2]
  def change
    create_table :check_results do |t|
      t.references :cluster_check, null: false
      t.date :date, null: false
      t.references :user, foreign_key: true, null: false
      t.string :result, null: false
      t.string :comment, null: true
      t.references :log, null: true
    end
  end
end
