class AddCompletionTimeToCase < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :completed_at, :datetime, null: true
  end
end
