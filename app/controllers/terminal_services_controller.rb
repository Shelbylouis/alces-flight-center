class TerminalServicesController < ApplicationController
  def show
    config = @site.terminal_service
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
