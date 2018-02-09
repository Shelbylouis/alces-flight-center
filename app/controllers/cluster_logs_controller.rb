class ClusterLogsController < ApplicationController
  def index
    @title = 'Logs'
    @logs = @cluster.cluster_logs
  end
end
