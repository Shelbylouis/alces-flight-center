class AddTimeWorkedToCases < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :time_worked, :integer, default: 0, null: false
  end
end
