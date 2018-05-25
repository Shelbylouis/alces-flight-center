class AddVirtualServerTypeAndTypeOrderings < ActiveRecord::DataMigration
  def up
    # Add ordering to existing ComponentTypes.
    server = ComponentType.find_by_name('Server')
    server.update!(ordering: 2)
    disk_array = ComponentType.find_by_name('Disk array')
    disk_array.update!(ordering: 3)
    network_switch = ComponentType.find_by_name('Network switch')
    network_switch.update!(ordering: 4)

    # Add new virtual server type, with same AssetRecordFieldDefinitions as
    # server.
    ComponentType.create!(
      name: 'Virtual server',
      ordering: 1,
      asset_record_field_definitions: server.asset_record_field_definitions
    )
  end
end
