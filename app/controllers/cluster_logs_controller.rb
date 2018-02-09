class ClusterLogsController < ApplicationController
  def index
    @title = 'Logs'
    @logs = @cluster.cluster_logs
    @new_log = @cluster.cluster_logs.new
    @cases = @cluster.cases.order(created_at: :desc)
  end

  def create
    p log_params
    redirect_back fallback_location: @cluster
  end

  private

  def log_params
    params.require(:cluster_log)
          .permit(:details, case_ids: [])
          .to_h
          .merge(engineer: current_user)
          .tap do |h|
            h[:case_ids] = h[:case_ids].reject(&:blank?)
          end
  end
end
