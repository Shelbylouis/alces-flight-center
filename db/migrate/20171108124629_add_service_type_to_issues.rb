class AddServiceTypeToIssues < ActiveRecord::Migration[5.1]
  def change
    add_reference :issues, :service_type, foreign_key: true, null:true
  end
end
