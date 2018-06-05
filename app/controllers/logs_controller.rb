require 'slack-notifier'
class LogsController < ApplicationController
  # Ensure actions authorize the resource they operate on (using Pundit).
  after_action :verify_authorized

  def index
    @new_log = Log.new
    authorize @new_log
    @scope = @component || @cluster
    @logs = @scope.logs
    @cases = @scope.cases
    @components = @scope.components if @scope.is_a? Cluster
  end

  def create
    @scope = @component || @cluster # TODO: Generalise this
    new_log = @scope.logs.build(log_params)
    authorize new_log
    if new_log.save
      flash[:success] = 'Added new log entry'
    else
      error_flash_models [new_log], 'Could not add log entry'
    end
    SlackNotifier.log_notification(new_log)
    redirect_back fallback_location: @cluster
  end

  private

  def log_params
    params.require(:log)
          .permit(:details, :component_id, case_ids: [])
          .merge(engineer: current_user)
  end
end

