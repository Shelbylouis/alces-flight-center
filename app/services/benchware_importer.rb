require 'yaml'

class BenchwareImporter

  def initialize(cluster)
    @cluster = cluster
  end

  def from_file(file)
    from_text(file.read)
  end

  def from_text(text)
    import(YAML.load(text))
  end

  private

  def import(data)
    new_components = 0
    updated_components = 0
    puts "TODO actually import into #{@cluster}"

    return new_components, updated_components
  end


end
