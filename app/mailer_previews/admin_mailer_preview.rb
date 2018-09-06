class AdminMailerPreview < ApplicationMailerPreview
  def daily_open_cases_list
    admin = Case.active.map(&:assignee).compact.uniq.sample

    AdminMailer.daily_open_cases_list(
       admin,
       admin.assigned_cases.active.prioritised.map(&:id)
    )
  end

  def new_log
    log = Log.offset(rand(Log.count)).first
    AdminMailer.new_log(log)
  end

  def cluster_check_submission
    cluster = Cluster.find_by_name('Demo Cluster')
    AdminMailer.cluster_check_submission(cluster, user)
  end
end
