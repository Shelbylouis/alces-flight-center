class AddServiceIssuesAndCases < ActiveRecord::Migration[5.1]
  def change
    add_column :issues, :requires_service, :boolean, null: false, default: false
    add_reference :cases, :service, foreign_key: true, null: true
  end
end
