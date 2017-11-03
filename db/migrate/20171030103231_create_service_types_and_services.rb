class CreateServiceTypesAndServices < ActiveRecord::Migration[5.1]
  def change
    create_table :service_types do |t|
      t.string :name, null: false
      t.string :description
      t.boolean :automatic, null: false, default: false

      t.timestamps null: false
    end

    create_table :services do |t|
      t.string :name, null: false
      t.string :support_type, null: false, default: 'inherit'
      t.references :service_type, foreign_key: true
      t.references :cluster, foreign_key: true

      t.timestamps null: false
    end
  end
end
