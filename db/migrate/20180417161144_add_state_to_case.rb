class AddStateToCase < ActiveRecord::Migration[5.1]
  def change
    add_column :cases, :state, :text, default: 'new', null: false
  end
end
