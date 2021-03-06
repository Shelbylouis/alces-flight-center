require 'yaml'

class BenchwareImporter

  # If this group name appears in secondary_groups then, if the :primary_group
  # attribute does not map to a friendly name in UNIX_NAME_MAPPING, this group
  # is treated as the primary.
  NODES_GROUP_IDENT = 'nodes'.freeze

  # If nodes are in this primary group we don't import them at all.
  IGNORE_GROUPS = %w(orphan).freeze

  def initialize(cluster)
    @cluster = cluster
    @new_components = 0
    @updated_components = 0
    @invalid_components = []
  end

  def from_file(file)
    from_text(file.read)
  end

  def from_text(text)
    import(YAML.load(text))
  end

  private

  def import(data)
    data.each do |key, component|
      process_component(component.symbolize_keys)
    rescue
      @invalid_components << key
    end

    return @new_components, @updated_components, @invalid_components
  end

  def process_component(spec)
    existing = @cluster.components.find_by(name: spec[:name])
    if existing
      existing.info = spec[:info]
      existing.save!
      @updated_components += 1
    else
      process_new_component(spec)
    end
  end

  def process_new_component(spec)
    group_unix_name = group_from_spec(spec)

    unless IGNORE_GROUPS.include?(group_unix_name)

      group = group_from_unix(group_unix_name)

      group.components.create(
        name: spec[:name],
        info: spec[:info]
      )

      @new_components += 1

    end

  end

  def group_from_spec(spec)
    if UNIX_NAME_MAPPING.include?(spec[:primary_group])
      spec[:primary_group]
    elsif spec[:secondary_group]&.split(',')&.include?(NODES_GROUP_IDENT)
      NODES_GROUP_IDENT
    else
      spec[:primary_group]
    end
  end

  def group_from_unix(unix_name)
    @cluster.component_groups
            .where(unix_name: unix_name)
            .first_or_create(
              cluster: @cluster,
              unix_name: unix_name,
              name: name_from_unix(unix_name)
    )
  end

  UNIX_NAME_MAPPING = {
    'nodes' => 'Compute nodes',
    'sw' => 'Ethernet switches',
    'gpu' => 'GPU nodes',
    'himem' => 'Himem nodes',
    'ibsw' => 'Infiniband switches',
    'infra' => 'Infrastructure nodes',
    'login' => 'Login nodes',
    'mds' => 'Lustre MDS',
    'oss' => 'Lustre OSS',
    'master' => 'Masters',
    'masters' => 'Masters',
    'nfs' => 'NFS servers',
    'admin' => 'Site nodes',
    'viz' => 'Viz nodes',
    'phi' => 'Xeon Phi nodes',
    'array' => 'Disk arrays'
  }.freeze

  def name_from_unix(unix_name)
    UNIX_NAME_MAPPING[unix_name] || unix_name
  end

end
