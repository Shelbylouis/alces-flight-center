class MakeIssueDetailsTemplateNullable < ActiveRecord::Migration[5.1]
  def change
    change_column_null :issues, :details_template, true
  end
end
