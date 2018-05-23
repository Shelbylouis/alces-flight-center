class RemoveObsoleteColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :cases, :details, :string
    remove_column :issues, :details_template, :string
    remove_column :issues, :support_type, :string, null: false
  end
end
