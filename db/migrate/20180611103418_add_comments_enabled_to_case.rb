class AddCommentsEnabledToCase < ActiveRecord::Migration[5.2]
  def change
    add_column :cases, :comments_enabled, :boolean, default: false
  end
end
