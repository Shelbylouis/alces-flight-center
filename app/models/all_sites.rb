class AllSites
  include Draper::Decoratable
  def cases
    Case.all
  end

  def clusters
    Cluster.all
  end

  def readable_model_name
    'All Sites'
  end

  def ==(other_object)
    other_object.is_a?(AllSites)
  end

  def dashboard_case_path(kase)
    Rails.application.routes.url_helpers.cluster_case_path(kase.cluster, kase)
  end
end
