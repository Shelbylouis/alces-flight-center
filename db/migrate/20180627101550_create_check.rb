class CreateCheck < ActiveRecord::Migration[5.2]
  def change
    create_table :checks do |t|
      t.references :check_category, null: false
      t.string :name, null: false
      t.string :command, null: true
    end
  end
end
