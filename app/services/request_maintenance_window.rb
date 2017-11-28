
class RequestMaintenanceWindow
  attr_reader :support_case, :user

  def initialize(support_case:, user:)
    @support_case = support_case
    @user = user
  end

  def run
    associated_model = support_case.associated_model

    maintenance_window = MaintenanceWindow.create!(user: user, case: support_case)

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
