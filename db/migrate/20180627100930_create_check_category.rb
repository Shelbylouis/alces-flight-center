class CreateCheckCategory < ActiveRecord::Migration[5.2]
  def change
    create_table :check_categories do |t|
      t.string :name, null: false
    end
  end
end
