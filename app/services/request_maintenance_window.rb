
RequestMaintenanceWindow = KeywordStruct.new(
  :support_case,
  :user,
  :associated_model
) do
  def initialize(associated_model: nil, **kwargs)
    associated_model = associated_model || kwargs[:support_case]&.associated_model
    super(**kwargs, associated_model: associated_model)
  end

  def run
    MaintenanceWindow.create!(
      user: user,
      case: support_case,
      associated_model: associated_model
    ).tap { add_rt_ticket_correspondence }
  end

  private

  def add_rt_ticket_correspondence
    support_case.add_rt_ticket_correspondence(
      <<-EOF.squish
        Maintenance requested for #{associated_model.name} by #{user.name};
        to proceed this maintenance must be confirmed on the cluster dashboard:
        #{cluster_dashboard_url}.
      EOF
    )
  end

  def cluster_dashboard_url
    Rails.application.routes.url_helpers.cluster_url(associated_model.cluster)
  end
end
