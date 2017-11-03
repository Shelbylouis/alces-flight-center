class SwitchCasesStatusToFlag < ActiveRecord::Migration[5.1]
  def change
    remove_column :cases, :status, :string
    add_column :cases, :archived, :boolean, null: false, default: false
  end
end
