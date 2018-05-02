class SetClusterShortcodes < ActiveRecord::DataMigration
  def up
    Cluster.all.each do |cluster|

      shortcode = dedupe(base_shortcode(cluster.name)) do |code|
        !Cluster.where(shortcode: code).exists?
      end

      cluster.shortcode = shortcode
      cluster.save!
    end
  end

    private

  def base_shortcode(cluster_name)
    if cluster_name == 'Demo Cluster'
      'DEMO'
    else
      cluster_name[0, 3].upcase
    end
  end

  def dedupe(base, &test)
    if test.call(base)
      base
    else
      attempt_count = 0

      while attempt_count < 26
        attempt = "#{base}#{(attempt_count + 'A'.ord).chr}"
        if test.call(attempt)
          return attempt
        end
      end

      raise 'I can\'t handle how many duplicate cluster shortcodes there might be. Please migrate manually.'
    end
  end
end
