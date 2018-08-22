require 'yaml'

class BenchwareImporter

  def initialize(cluster)
    @cluster = cluster
    @new_components = 0
    @updated_components = 0
  end

  def from_file(file)
    from_text(file.read)
  end

  def from_text(text)
    import(YAML.load(text))
  end

  private

  def import(data)
    data.values.each do |component|
      process_component(component.symbolize_keys)
    end

    return @new_components, @updated_components
  end

  def process_component(spec)
    existing = @cluster.components.find_by(name: spec[:name])
    existing.info = spec[:info]
    existing.save!
    @updated_components += 1
  rescue ActiveRecord::RecordNotFound
    process_new_component(spec)
  end

  def process_new_component(spec)

  end

end
