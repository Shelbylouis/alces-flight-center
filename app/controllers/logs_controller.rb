require 'slack-notifier'
class LogsController < ApplicationController
  def index
    @scope = @component || @cluster
    @new_log = Log.new(@scope.class.name.downcase => @scope)
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
      AdminMailer.new_log(new_log).deliver_later
    else
      error_flash_models [new_log], 'Could not add log entry'
    end
    redirect_back fallback_location: @cluster
  end

  def preview
    @new_log = @scope.logs.build(log_params)
    authorize @new_log, :create?

    render layout: false
  end

  def write
    @new_log = @scope.logs.build(log_params)
    authorize @new_log, :create?

    render layout: false
  end

  private

  def log_params
    params.require(:log)
          .permit(:details, :component_id, case_ids: [])
          .merge(engineer: current_user)
  end
end
