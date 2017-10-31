
CaseCategory.create!(name: 'User Management').tap do |user_management|
  user_management.issues.create!(
    name: 'Additional users/groups',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give the username, primary group, and any additional groups for
      each user to be created; give the name and any users which should be
      added for each group to be created.
    EOF
  )
end

CaseCategory.create!(name: 'Application Management').tap do |application_management|
  application_management.issues.create!(
    name: 'From available Alces Gridware',
    support_type: 'managed',
    details_template: <<-EOF.squish
      See https://gridware.alces-flight.com for the full directory of available
      Gridware; please give the package name and version of each Gridware
      package you would like installed.
    EOF

  )
  application_management.issues.create!(
    name: 'Custom open-source',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give a URL where the open-source package to install can be found,
      and any special compilation settings or other additional details needed.
    EOF
  )
  application_management.issues.create!(
    name: 'Custom commercial',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give a URL where the commercial package to install can be found,
      and any installation keys or other additional details needed.
    EOF
  )
end

CaseCategory.create!(name: 'Quota/Fair Usage Management').tap do |quota_management|
  quota_management.issues.create!(
    name: 'Storage quota changes',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give details of the storage quota changes you require.
    EOF
  )
  quota_management.issues.create!(
    name: 'Scheduler changes',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give details of the scheduler changes you require.
    EOF
  )
end

CaseCategory.create!(name: 'Suspected Hardware Issue').tap do |hardware|
  hardware.issues.create!(
    name: 'Hardware issue',
    support_type: 'managed',
    requires_component: true,
    details_template: <<-EOF.squish
      Please give as much additional information as possible about the
      suspected hardware issue.
    EOF
  )
end

CaseCategory.create!(name: 'End User Assistance').tap do |end_user_assistance|
  end_user_assistance.issues.create!(
    name: 'Problem jobs',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the problem job.
    EOF

  )
  end_user_assistance.issues.create!(
    name: 'Job running how-to/assistance',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the problems you are
      having running a job.
    EOF
  )
  end_user_assistance.issues.create!(
    name: 'Job script how-to/assistance',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the problems you are
      having with your job script.
    EOF
  )
  end_user_assistance.issues.create!(
    name: 'Application problems/bugs',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the application problem
      you are encountering .
    EOF
  )
  end_user_assistance.issues.create!(
    name: 'Self application install assistance',
    support_type: 'managed',
    details_template: <<-EOF.squish
      Please give as much information as possible about the application you are
      trying to install and the problem you are encountering.
    EOF
  )
end

CaseCategory.create!(name: 'Change Component Status').tap do |change_status|
  change_status.issues.create!(
    name: 'Request self-management of component',
    support_type: 'managed',
    requires_component: true,
    identifier: Issue::IDENTIFIERS.request_component_becomes_advice,
    details_template: <<-EOF.squish
      Please indicate why you would like self-management of this component.
    EOF
  )
  change_status.issues.create!(
    name: 'Relinquish self-management of component',
    support_type: 'advice-only',
    requires_component: true,
    identifier: Issue::IDENTIFIERS.request_component_becomes_managed,
    details_template: <<-EOF.squish
      Note that when a component becomes managed it must first be reset to its
      initial state, without any custom modifications. Please indicate why you
      would like to relinquish self-management of this component.
    EOF
  )
end

CaseCategory.create!(name: 'Consultancy').tap do |consultancy|
  consultancy.issues.create!(
    name: 'Request custom consultancy',
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
    level: 'component',
    field_names: [
      'IP Address/Netmask/Network/Gateway',
    ],
  },
  {
    component_types: [disk_array, network_switch],
    level: 'group',
    field_names: [
      'Firmware revision',
      'Configuration profile applied',
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

automatic_services = [
  'User Management',
  'Workload Scheduler Management',
  'HPC Environment',
]

automatic_services.each do |service_name|
  ServiceType.create!(name: service_name, automatic: true)
end

ServiceType.create!(name: 'File System', automatic: false)

User.create!(
  name: 'Temporary admin',
  admin: true,
  email: 'admin@example.com',
  password: 'password'
)
