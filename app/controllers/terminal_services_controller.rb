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
      ui: config.console_ui.merge({
        breadcrumbs: breadcrumbs(config)
      }),
      site: {
        id: site.id,
        link: {
          site: 'Center',
          path: user_aware_site_path(site),
        },
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

  private

  def breadcrumbs(service)
    site = service.site
    cluster = @scope.is_a?(Cluster) ? @scope : nil
    [
      current_user.admin? ? {
        text: 'All sites',
        icon: 'globe',
        link: {
          site: 'Center',
          path: sites_path,
        },
      } : nil,
      {
        text: site.name,
        icon: 'institution',
        link: {
          site: 'Center',
          path: user_aware_site_path(site),
        }
      },
      cluster.nil? ? nil : {
        text: cluster.name,
        icon: 'server',
        link: {
          site: 'Center',
          path: cluster_path(cluster),
        },
      },
      {
        text: service.console_ui['title'],
        icon: service.console_ui['icon'],
        link: {
          path: @scope.decorate.terminal_service_path(service),
        },
      },
    ].compact
  end

  def user_aware_site_path(site)
    current_user.admin? ? site_path(site) : root_path
  end
end
