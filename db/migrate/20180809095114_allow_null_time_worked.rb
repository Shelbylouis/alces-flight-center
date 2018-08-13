class AllowNullTimeWorked < ActiveRecord::Migration[5.2]
  def change
    change_column_null :cases, :time_worked, true
    change_column_default :cases, :time_worked, nil
  end
end
