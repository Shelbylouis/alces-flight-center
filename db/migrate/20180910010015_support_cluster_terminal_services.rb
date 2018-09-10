class SupportClusterTerminalServices < ActiveRecord::Migration[5.2]
  def change
    add_column :terminal_services, :type, :string,
      null: false,
      default: 'SiteTerminalService'
    change_column_default :terminal_services, :type,
      from: 'SiteTerminalService',
      to: nil

    change_column_null :terminal_services, :site_id, true
    add_reference :terminal_services, :cluster,
      null: true,
      foreign_key: true
  end
end
