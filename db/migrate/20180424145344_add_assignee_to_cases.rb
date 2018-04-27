class AddAssigneeToCases < ActiveRecord::Migration[5.1]
  def change
    add_reference :cases, :assignee, foreign_key: { to_table: :users }, null: true
  end
end
