class AddSubjectToCases < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :subject, :text, null: true
  end
end
