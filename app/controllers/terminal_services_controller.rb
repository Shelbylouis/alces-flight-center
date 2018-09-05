class TerminalServicesController < ApplicationController
  def show
    config = @site.terminal_services.find_by(service_type: params[:service_type])
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
        name: site.name,
      },
      # Deprecated structure.  Remove once flight console and flight console
      # api have been deployed to not use it.
      flight_directory_config: {
        hostname: config.hostname,
        username: config.username,
        ssh_key: config.encrypted_ssh_key,
      },
    }
  end
end
