
class RequestMaintenanceWindow
  attr_reader :support_case, :user, :associated_model

  def initialize(support_case:, user:, associated_model: nil)
    @support_case = support_case
    @user = user
    @associated_model = associated_model || support_case.associated_model
  end

  def run
    maintenance_window = MaintenanceWindow.create!(
      user: user,
      case: support_case,
      associated_model: associated_model
    )

    cluster_dashboard_url =
      Rails.application.routes.url_helpers.cluster_url(associated_model.cluster)
    support_case.add_rt_ticket_correspondence(
      <<-EOF.squish
        Maintenance requested for #{associated_model.name} by #{user.name};
        to proceed this maintenance must be confirmed on the cluster dashboard:
        #{cluster_dashboard_url}.
      EOF
    )

    maintenance_window
  end
end
