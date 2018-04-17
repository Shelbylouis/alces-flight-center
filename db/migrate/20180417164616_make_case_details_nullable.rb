class MakeCaseDetailsNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null :cases, :details, true
  end
end
