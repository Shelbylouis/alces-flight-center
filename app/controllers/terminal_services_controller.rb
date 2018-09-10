class TerminalServicesController < ApplicationController
  def show
    config = @scope.terminal_services.find_by(service_type: params[:service_type])
    if config.nil?
      render json: {}, status: 404
      return
    end

    authorize config, :show?
    site = config.site

    render json: {
      ssh: {
        hostname: config.hostname,
        username: config.username,
        key: config.encrypted_ssh_key,
      },
      ui: config.console_ui,
      site: {
        id: site.id,
        name: site.name,
      },
      cluster: cluster_json,
      # Deprecated structure.  Remove once flight console and flight console
      # api have been deployed to not use it.
      flight_directory_config: {
        hostname: config.hostname,
        username: config.username,
        ssh_key: config.encrypted_ssh_key,
      },
    }
  end

  private

  def cluster_json
    return nil unless @scope.is_a?(Cluster)
    {
      id: @scope.id,
      name: @scope.name,
    }
  end
end
