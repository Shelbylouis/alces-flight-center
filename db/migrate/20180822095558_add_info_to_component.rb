class AddInfoToComponent < ActiveRecord::Migration[5.2]
  def change
    add_column :components, :info, :text, null: false, default: ''
  end
end
