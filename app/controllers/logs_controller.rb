class LogsController < ApplicationController
  def index
    @title = 'Logs'
    @new_log = Log.new
    @scope = @component || @cluster
    @logs = @scope.logs
    @cases = @scope.cases.order(created_at: :desc)
    @components = @scope.components if @scope.is_a? Cluster
  end

  def create
    @scope = @component || @cluster # TODO: Generalise this
    new_log = @scope.logs.build(log_params)
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
          .permit(:details, :component_id, case_ids: [])
          .merge(engineer: current_user)
  end
end

