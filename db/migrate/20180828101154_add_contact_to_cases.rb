class AddContactToCases < ActiveRecord::Migration[5.2]
  def change
    add_reference :cases, :contact, foreign_key: { to_table: :users }, null: true
  end
end
