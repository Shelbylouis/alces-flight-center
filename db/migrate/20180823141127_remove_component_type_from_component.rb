class RemoveComponentTypeFromComponent < ActiveRecord::Migration[5.2]
  def change
    remove_column :components, :component_type, :string, null: false
  end
end
