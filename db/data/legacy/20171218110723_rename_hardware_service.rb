class RenameHardwareService < ActiveRecord::DataMigration
  def up
    Service.find_by_name!('Hardware').update!(name: 'Hardware Management')
  end
end
