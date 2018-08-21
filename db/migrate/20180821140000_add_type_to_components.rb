class AddTypeToComponents < ActiveRecord::Migration[5.2]
  def change
    add_column :components, :component_type, :string
  end
end
