class AddInternalToClusterParts < ActiveRecord::Migration[5.1]
  def change
    add_column :components, :internal, :boolean, null: true, default: false
    add_column :services,   :internal, :boolean, null: true, default: false
  end
end
