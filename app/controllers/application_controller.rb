require 'exceptions'

class ApplicationController < ActionController::Base
  include Clearance::Controller
  protect_from_forgery with: :exception
  decorates_assigned :site

  before_action :assign_current_user
  before_action :define_navigation_variables

  rescue_from ReadPermissionsError, with: :not_found

  private

  def assign_current_user
    RequestStore.store[:current_user] = current_user
  end

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
    when /^\/component-groups/
      id = params[:component_group_id] || params[:id]
      @component_group = ComponentGroup.find(id)
    when /^\/services/
      id = params[:service_id] || params[:id]
      @cluster_part = Service.find(id)
    end

    @cluster ||= if @cluster_part
                   @cluster_part.cluster
                 elsif @component_group
                   @component_group.cluster
                 end
    if @cluster_part.respond_to?(:component_group)
      @component_group = @cluster_part.component_group
    end
    @site = @cluster.site if @cluster && current_user.admin?
  end

  def format_errors(model)
    # XXX Improve error handling - for now we just return a formatted string of
    # all errors; could be worth returning JSON which can be decoded and
    # displayed inline with fields in app.
    model.errors.messages.map do |field, messages|
      "#{field} #{messages.join(', ')}"
    end.join('; ')
  end
end
