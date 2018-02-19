class LogsController < ApplicationController
  def index
    @title = 'Logs'
    @new_log = Log.new
    @logs = @cluster.logs
    @cases = @cluster.cases.order(created_at: :desc)
  end

  def create
    new_log = @cluster.logs.build(log_params)
    if new_log.save
      flash[:success] = 'Added new log entry'
    else
      error_flash_models [new_log], 'Could not add log entry'
    end
    redirect_back fallback_location: @cluster
  end

  private

  def log_params
    params.require(:log)
          .permit(:details, case_ids: [])
          .merge(engineer: current_user)
  end
end
