class ClusterLogsController < ApplicationController
  def index
    @title = 'Logs'
    @logs = @cluster.cluster_logs
    @new_log = @cluster.cluster_logs.new
    @cases = @cluster.cases.order(created_at: :desc)
  end

  def create
  end
end
