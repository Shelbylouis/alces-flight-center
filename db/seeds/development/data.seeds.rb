
site = Site.create!(
  name: 'Liverpool University',
  description: <<-EOF.strip_heredoc
    Clifton Computer Science Building

    Brownlow Hill

    Liverpool

    L69 72X
  EOF
)

User.create!(
  site: site,
  name: 'Dr Cliff Addison',
  email: 'caddison@example.com',
  password: 'password',
)

AdditionalContact.create!(
  site: site,
  email: 'mailing-list@example.com'
)
AdditionalContact.create!(
  site: site,
  email: 'another.contact@example.com'
)

Cluster.create!(
  site: site,
  name: 'Hamilton Research Computing Cluster',
  description: 'A cluster for research computing',
  support_type: 'managed'
).tap do |cluster|
  ComponentGroup.create!(
    cluster: cluster,
    name: 'Rack A1 nodes',
    component_type: ComponentType.find_by_name('Server'),
    genders_host_range: 'node[01-20]'
  ).tap do |group|

    AssetRecordField.create!(
      component_group: group,
      asset_record_field_definition: AssetRecordFieldDefinition.find_by_field_name('Manufacturer/Model name'),
      value: 'Dell C6420'
    )
    AssetRecordField.create!(
      component_group: group,
      asset_record_field_definition: AssetRecordFieldDefinition.find_by_field_name('OS Deployed/OS Profile'),
      value: 'CentOS 7'
    )

    group.reload
    group.components.each_with_index do |component, index|
      AssetRecordField.create!(
        component: component,
        asset_record_field_definition: AssetRecordFieldDefinition.find_by_field_name('BMC IP Address/Netmask/Network/Gateway'),
        value: "1.2.3.#{index + 1}"
      )
    end
  end

  group = ComponentGroup.create!(
    cluster: cluster,
    name: 'Self-managed nodes',
    component_type: ComponentType.find_by_name('Server'),
    genders_host_range: 'self_managed[01-03]'
  )
  group.reload
  group.components.each do |component|
    component.support_type = 'advice'
    component.save!
  end


  ComponentGroup.create!(
    cluster: cluster,
    name: 'Rack A1 switches',
    component_type: ComponentType.find_by_name('Network switch')
  ).tap do |group|
    Component.create!(
      component_group: group,
      name: 'Rack A1 Dell N1545 1Gb Ethernet switch 1'
    )
    Component.create!(
      component_group: group,
      name: 'Rack A1 Dell N1545 1Gb Ethernet switch 2 (self-managed)',
      support_type: 'advice'
    )
    Component.create!(
      component_group: group,
      name: 'Rack A1 Omnipath Edge switch 45pt'
    )
  end

  # Upload some documents to use in development for this cluster to S3.
  Development::Utils.upload_document_fixtures_for(cluster)
end

Cluster.create!(
  site: site,
  name: 'Additional cluster',
  description: 'An additional cluster for development',
  support_type: 'advice'
).tap do |cluster|
  group = ComponentGroup.create!(
    cluster: cluster,
    name: 'Additional cluster nodes',
    component_type: ComponentType.find_by_name('Server'),
    genders_host_range: 'anode[01-05]'
  )
  group.reload
  managed_component = group.components.last
  managed_component.support_type = 'managed'
  managed_component.save!
end
