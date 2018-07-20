class TerminalServicesController < ApplicationController
  def show
    config = @site.flight_directory_config
    if config.nil?
      render json: {}, status: 404
      return
    end

    authorize config, :show?
    site = config.site

    render json: {
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
