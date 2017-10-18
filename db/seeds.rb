
CaseCategory.create!(name: 'User Management').tap do |user_management|
  Issue.create!(
    name: 'Additional users/groups',
    case_category: user_management,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give the username, primary group, and any additional groups for
      each user to be created; give the name and any users which should be
      added for each group to be created.
    EOF
  )
end

CaseCategory.create!(name: 'Application Management').tap do |application_management|
  Issue.create!(
    name: 'From available Alces Gridware',
    case_category: application_management,
    support_type: 'managed',
    details_template: <<-EOF.squish
      See https://gridware.alces-flight.com for the full directory of available
      Gridware; please give the package name and version of each Gridware
      package you would like installed.
    EOF

  )
  Issue.create!(
    name: 'Custom open-source',
    case_category: application_management,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give a URL where the open-source package to install can be found,
      and any special compilation settings or other additional details needed.
    EOF
  )
  Issue.create!(
    name: 'Custom commercial',
    case_category: application_management,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give a URL where the commercial package to install can be found,
      and any installation keys or other additional details needed.
    EOF
  )
end

CaseCategory.create!(name: 'Quota/Fair Usage Management').tap do |quota_management|
  Issue.create!(
    name: 'Storage quota changes',
    case_category: quota_management,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give details of the storage quota changes you require.
    EOF
  )
  Issue.create!(
    name: 'Scheduler changes',
    case_category: quota_management,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give details of the scheduler changes you require.
    EOF
  )
end

CaseCategory.create!(name: 'Suspected Hardware Issue').tap do |hardware|
  Issue.create!(
    name: 'Hardware issue',
    case_category: hardware,
    support_type: 'managed',
    requires_component: true,
    details_template: <<-EOF.squish
      Please give as much additional information as possible about the
      suspected hardware issue.
    EOF
  )
end

CaseCategory.create!(name: 'End User Assistance').tap do |end_user_assistance|
  Issue.create!(
    name: 'Problem jobs',
    case_category: end_user_assistance,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the problem job.
    EOF

  )
  Issue.create!(
    name: 'Job running how-to/assistance',
    case_category: end_user_assistance,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the problems you are
      having running a job.
    EOF
  )
  Issue.create!(
    name: 'Job script how-to/assistance',
    case_category: end_user_assistance,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the problems you are
      having with your job script.
    EOF
  )
  Issue.create!(
    name: 'Application problems/bugs',
    case_category: end_user_assistance,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the application problem
      you are encountering .
    EOF
  )
  Issue.create!(
    name: 'Self application install assistance',
    case_category: end_user_assistance,
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the application you are
      trying to install and the problem you are encountering.
    EOF
  )
end

CaseCategory.create!(name: 'Consultancy').tap do |consultancy|
  Issue.create!(
    name: 'Request custom consultancy',
    case_category: consultancy,
    support_type: 'advice',
    details_template: <<-EOF.squish
      Please describe the specialist support you would like to request from
      Alces Software.
    EOF
  )
end

server = ComponentType.create!(name: 'Server')
disk_array = ComponentType.create!(name: 'Disk array')
network_switch = ComponentType.create!(name: 'Network switch')

all_types = [server, disk_array, network_switch]

[
  # Define AssetRecordFieldDefinitions commmon to all ComponentTypes.
  {
    component_types: all_types,
    level: 'component',
    field_names: [
      'Serial Number/Asset Tag',
    ],
  },
  {
    component_types: all_types,
    level: 'group',
    field_names: [
      'Manufacturer/Model name',
      'List all labels applied',
    ],
  },

  # Define AssetRecordFieldDefinitions commmon to disk array and network switch
  # ComponentTypes.
  {
    component_types: [disk_array, network_switch],
    level: 'group',
    field_names: [
      'Firmware revision',
      'Configuration profile applied',
      'IP Address/Netmask/Network/Gateway',
      'Username/Password',
      'Non-standard settings (changes from standard base configuration listed as menu navigation links)',
    ],
  },

  # Define AssetRecordFieldDefinitions unique to server ComponentType.
  {
    component_types: [server],
    level: 'group',
    field_names: [
      'Firmware revision (BIOS/BMC/Other)',
      'BMC username/password',
      'BIOS Profile Applied',
      'Non-standard settings (BMC or BIOS) (changes from standard base configuration listed as menu navigation links)',
      'Internal Disk Profile Applied',
      'Internal Disk Configuration Notes (listed as menu navigation links where possible)',
      'Internal Disk Profile Applied',
      'Internal Disk Configuration Notes',
      'OS Deployed/OS Profile',
      'Network connections (adapter/port/network)',
      'Burn-in test profile',
      'Burn-in status',
      'Additional adapters installed, type and configuration notes',
      'Comments',
    ],
  },
  {
    component_types: [server],
    level: 'component',
    field_names: [
      'BMC IP Address/Netmask/Network/Gateway',
    ],
  },
].each do |definition_group|
  definition_group[:field_names].each do |field_name|
    AssetRecordFieldDefinition.create!(
      field_name: field_name,
      level: definition_group[:level],
      component_types: definition_group[:component_types]
    )
  end
end

User.create!(
  name: 'Temporary admin',
  admin: true,
  email: 'admin@example.com',
  password: 'password'
)
