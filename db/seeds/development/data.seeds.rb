
admin = User.first

site = Site.create!(
  name: 'Liverpool University',
  description: <<-EOF.strip_heredoc
    Clifton Computer Science Building

    Brownlow Hill

    Liverpool

    L69 72X
  EOF
)

first_user = site.users.create!(
  name: 'Dr Cliff Addison',
  email: 'caddison@example.com',
  password: 'password',
  primary_contact: true
)

second_user = site.users.create!(
  name: 'Another User',
  email: 'another.user@example.com',
  password: 'password'
)

site.additional_contacts.create!(
  email: 'mailing-list@example.com'
)
site.additional_contacts.create!(
  email: 'another.contact@example.com'
)

network_expansion = ExpansionType.create!(
  name: 'Gigabit Network Adapter'
)

memory_expansion = ExpansionType.create!(
  name: '256GB SSD'
)

dell_server = ComponentMake.create!(
  manufacturer: 'Dell',
  model: 'zippy',
  knowledgebase_url: 'http://why.did@i-write.this/in#full',
  component_type: ComponentType.find_by_name('Server')
)

dell_server.default_expansions.create!(
  expansion_type: network_expansion,
  slot: '1A',
  ports: 4
)

dell_server.default_expansions.create!(
  expansion_type: memory_expansion,
  slot: '2B',
  ports: 1
)

main_cluster = site.clusters.create!(
  name: 'Hamilton Research Computing Cluster',
  description: 'A cluster for research computing',
  support_type: 'managed',
  charging_info: <<~EOF
    Most chargeable issues will cost you 1 credit per hour of engineer-time
    spent investigating that issue, rounded up to the nearest hour.

    Asking for ridiculous things will cost you 5+ credits.
  EOF
).tap do |cluster|
  cluster.credit_deposits.create!(amount: 10, user: admin)
  cluster.credit_deposits.create!(amount: 8, user: admin)

  cluster.component_groups.create!(
    name: 'Rack A1 nodes',
    component_make: dell_server,
    genders_host_range: 'node[01-20]'
  ).tap do |group|

    group.asset_record_fields.create!(
      asset_record_field_definition: AssetRecordFieldDefinition.find_by_field_name('Manufacturer/Model name'),
      value: 'Dell C6420'
    )
    group.asset_record_fields.create!(
      asset_record_field_definition: AssetRecordFieldDefinition.find_by_field_name('OS Deployed/OS Profile'),
      value: 'CentOS 7'
    )

    group.components.each_with_index do |component, index|
      component.asset_record_fields.create!(
        component: component,
        asset_record_field_definition: AssetRecordFieldDefinition.find_by_field_name('BMC IP Address/Netmask/Network/Gateway'),
        value: "1.2.3.#{index + 1}"
      )
    end
  end

  cluster.component_groups.create!(
    name: 'Self-managed nodes',
    component_make: dell_server,
    genders_host_range: 'self_managed[01-03]'
  ).tap do |group|
    group.components.each do |component|
      component.support_type = 'advice'
      component.save!
    end
  end

  switch_make = ComponentMake.create!(
    manufacturer: 'Dell',
    model: 'a_switch_123',
    knowledgebase_url: 'example.com',
    component_type: ComponentType.find_by_name('Network switch'),
  )
  cluster.component_groups.create!(
    name: 'Rack A1 switches',
    component_make: switch_make
  ).tap do |group|
    group.components.create!(
      component_group: group,
      name: 'Rack A1 Dell N1545 1Gb Ethernet switch 1'
    )
    group.components.create!(
      component_group: group,
      name: 'Rack A1 Dell N1545 1Gb Ethernet switch 2 (self-managed)',
      support_type: 'advice'
    )
    group.components.create!(
      component_group: group,
      name: 'Rack A1 Omnipath Edge switch 45pt'
    )
  end

  file_system = ServiceType.find_by_name('File System')
  {
    lustre: :managed,
    nfs1: :advice,
    nfs2: :managed
  }.each do |name, support_type|
    cluster.services.create!(
      service_type: file_system,
      name: name,
      support_type: support_type
    )
  end

  # Upload some documents to use in development for this cluster to S3.
  Development::Utils.upload_document_fixtures_for(cluster)
end

site.clusters.create!(
  name: 'Additional cluster',
  description: 'An additional cluster for development',
  support_type: 'advice'
).tap do |cluster|
  cluster.component_groups.create!(
    name: 'Additional cluster nodes',
    component_make: dell_server,
    genders_host_range: 'anode[01-05]'
  )
end

# Run data migrations (from `rails-data-migrations` Gem) to (attempt to) keep
# seeds in sync with production data.
Rake::Task['data:migrate'].invoke


# This seed data depends on the data migrations changes above...

chargeable_issue = Issue.where(chargeable: true).first
non_chargeable_issue = Issue.find_by_name!('Application problems/bugs')
main_cluster_hpc_environment = Service.find_by_name('HPC Environment')

main_cluster.cases.create!(
  issue: chargeable_issue,
  details: 'Please do some reasonable things Alces',
  user: first_user,
  last_known_ticket_status: 'resolved'
).tap do |support_case|
  support_case.create_credit_charge!(amount: 1, user: admin)
end

main_cluster.cases.create!(
  issue: chargeable_issue,
  details: 'Please do some ridiculous things Alces',
  user: second_user,
  last_known_ticket_status: 'rejected',
).tap do |support_case|
  support_case.create_credit_charge!(amount: 7, user: admin)
end

main_cluster.cases.create!(
  issue: chargeable_issue,
  user: first_user,
  details: 'Please give me support Alces'
)

main_cluster.cases.create!(
  issue: non_chargeable_issue,
  user: second_user,
  details: 'I need support please',
  service: main_cluster_hpc_environment,
)

main_cluster.cases.create!(
  issue: non_chargeable_issue,
  user: second_user,
  details: 'More support please',
  service: main_cluster_hpc_environment,
)

virtual_server_make = ComponentMake.create!(
  manufacturer: 'N/A',
  model: 'Libvirt',
  knowledgebase_url: 'example.com',
  component_type: ComponentType.find_by_name('Virtual server'),
)
main_cluster.component_groups.create!(
  name: 'Appliances',
  component_make: virtual_server_make,
).tap do |group|
  group.components.create!(
    name: 'Alces Controller Appliance',
    internal: true
  )

  group.components.create!(
    name: 'Crazy Site Appliance',
    internal: false,
    support_type: 'advice'
  )
end
