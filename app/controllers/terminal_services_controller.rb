class TerminalServicesController < ApplicationController
  def show
    config = @site.flight_directory_config || @site.build_flight_directory_config
    authorize config, :show?
    site = config.site

    render json: {
      flight_directory_config: {
        hostname: config.hostname,
        username: config.username,
      },
      site: {
        name: site.name,
      },
    }
  end
end
