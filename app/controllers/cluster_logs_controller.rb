class ClusterLogsController < ApplicationController
  def index
    @title = 'Logs'
    @logs = @cluster.cluster_logs
    @new_case = @cluster.cases.new
    @cases = @cluster.cases.order(created_at: :desc)
  end

  def create
  end
end
