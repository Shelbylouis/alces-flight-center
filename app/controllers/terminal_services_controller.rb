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
      flight_directory_config: {
        hostname: config.hostname,
        username: config.username,
        ssh_key: config.encrypted_ssh_key,
      },
      site: {
        name: site.name,
      },
    }
  end
end
