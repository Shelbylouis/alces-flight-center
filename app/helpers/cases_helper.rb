module CasesHelper

  def case_path(kase)
    Rails.application.routes.url_helpers.cluster_case_path(kase.cluster, kase)
  end

  def case_url(kase)
    Rails.application.routes.url_helpers.cluster_case_url(kase.cluster, kase)
  end

end
