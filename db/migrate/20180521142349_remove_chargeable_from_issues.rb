class RemoveChargeableFromIssues < ActiveRecord::Migration[5.1]
  def change
    remove_column :issues, :chargeable, :boolean
  end
end
