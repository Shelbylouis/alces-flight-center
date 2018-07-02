class TerminalServicesController < ApplicationController
  def show
    config = policy_scope(FlightDirectoryConfig).first || FlightDirectoryConfig.new
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
