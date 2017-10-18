class AddSupportTypeToComponentsAndIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :components, :support_type, :string, null: false, default: 'inherit'
    add_column :issues, :support_type, :string
  end
end
