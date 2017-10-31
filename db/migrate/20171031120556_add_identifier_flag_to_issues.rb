class AddIdentifierFlagToIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :issues, :identifier, :string, null: true
  end
end
