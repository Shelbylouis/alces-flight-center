class CreateComponents < ActiveRecord::Migration[5.1]
  def change
    create_table :components do |t|
      t.string :name
      t.text :description
      t.string :component_type
      t.references :cluster, foreign_key: true

      t.timestamps
    end
  end
end
