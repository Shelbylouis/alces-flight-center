
site = Site.create!(
  name: 'Liverpool University',
  description: <<-EOF.strip_heredoc
    Clifton Computer Science Building

    Brownlow Hill

    Liverpool

    L69 72X
  EOF
)

site.users.create!(
  name: 'Dr Cliff Addison',
  email: 'caddison@example.com',
  password: 'password'
)

site.users.create!(
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

site.clusters.create!(
  name: 'Hamilton Research Computing Cluster',
  description: 'A cluster for research computing',
  support_type: 'managed'
).tap do |cluster|
  cluster.component_groups.create!(
    name: 'Rack A1 nodes',
    component_type: ComponentType.find_by_name('Server'),
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
    component_type: ComponentType.find_by_name('Server'),
    genders_host_range: 'self_managed[01-03]'
  ).tap do |group|
    group.components.each do |component|
      component.support_type = 'advice'
      component.save!
    end
  end

  cluster.component_groups.create!(
    name: 'Rack A1 switches',
    component_type: ComponentType.find_by_name('Network switch')
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
  ['lustre', 'nfs1', 'nfs2'].each do |name|
    cluster.services.create!(service_type: file_system, name: name)
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
    component_type: ComponentType.find_by_name('Server'),
    genders_host_range: 'anode[01-05]'
  )
end
