require 'exceptions'

class ApplicationController < ActionController::Base
  include Clearance::Controller
  protect_from_forgery with: :exception
  decorates_assigned :site

  before_action :set_sentry_raven_context
  before_action :assign_current_user
  before_action :define_navigation_variables

  rescue_from ReadPermissionsError, with: :not_found

  def error_flash_models(models, header)
    flash[:error] = header + "\n" + models.map do |model|
      prefix = block_given? ? ((yield model).to_s + ': ') : ''
      prefix + model.errors.full_messages.to_s
    end.join("\n")
  end

  private

  def set_sentry_raven_context
    Raven.user_context(id: current_user&.id)
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

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

    if request.path == '/' && !current_user.admin?
      return @scope = @site = current_user.site
    end

    @scope = case request.path
             when /^\/sites/
               id = params[:site_id] || params[:id]
               @site = Site.find(id) if current_user.admin?
             when /^\/clusters/
               id = params[:cluster_id] || params[:id]
               @cluster = Cluster.find(id)
             when /^\/components/
               id = params[:component_id] || params[:id]
               @cluster_part = @component = Component.find(id)
             when /^\/component-groups/
               id = params[:component_group_id] || params[:id]
               @component_group = ComponentGroup.find(id)
             when /^\/services/
               id = params[:service_id] || params[:id]
               @cluster_part = @service = Service.find(id)
             end
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
