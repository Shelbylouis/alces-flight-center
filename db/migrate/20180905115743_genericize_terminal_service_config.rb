class GenericizeTerminalServiceConfig < ActiveRecord::Migration[5.2]
  def change
    rename_table :flight_directory_configs, :terminal_services
    add_column :terminal_services, :service_type, :string,
      null: false,
      default: 'directory'
    change_column_default :terminal_services, :service_type,
      from: 'directory',
      to: nil
  end
end
