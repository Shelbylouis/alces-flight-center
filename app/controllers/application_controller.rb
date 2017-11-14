class ApplicationController < ActionController::Base
  include Clearance::Controller
  protect_from_forgery with: :exception

  before_action :define_navigation_variables

  def current_site
    @site
  end

  # From https://stackoverflow.com/a/4983354/2620402.
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def define_navigation_variables
    return unless current_user

    @site = current_user.site

    case request.path
    when /^\/sites/
      id = params[:site_id] || params[:id]
      @site = Site.find(id) if current_user.admin?
    when /^\/clusters/
      id = params[:cluster_id] || params[:id]
      @cluster = Cluster.find(id)
    when /^\/components/
      id = params[:component_id] || params[:id]
      @cluster_part = Component.find(id)
    when /^\/services/
      id = params[:service_id] || params[:id]
      @cluster_part = Service.find(id)
    end

    @cluster = @cluster_part.cluster if @cluster_part
    @site = @cluster.site if @cluster && current_user.admin?
  end
end
