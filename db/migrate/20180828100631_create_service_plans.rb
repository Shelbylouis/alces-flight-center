class CreateServicePlans < ActiveRecord::Migration[5.2]
  def change
    create_table :service_plans do |t|
      t.references :cluster, foreign_key: true, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
    end
  end
end
