class AddDetailsTemplateToIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :issues, :details_template, :string
  end
end
