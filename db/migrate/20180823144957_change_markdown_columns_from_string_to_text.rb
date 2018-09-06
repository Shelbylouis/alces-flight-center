class ChangeMarkdownColumnsFromStringToText < ActiveRecord::Migration[5.2]
  def up
    change_column :change_requests, :description, :text
    change_column :check_results, :comment, :text
    change_column :case_comments, :text, :text
  end

  def down
    change_column :change_requests, :description, :string
    change_column :check_results, :comment, :string
    change_column :case_comments, :text, :string
  end
end
