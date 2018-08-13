class AddSshKeyToFlightDirectoryConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :flight_directory_configs, :encrypted_ssh_key, :string,
      limit: 4 * 1024,
      null: false
  end
end
