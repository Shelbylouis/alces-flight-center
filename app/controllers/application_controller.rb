require 'exceptions'

class ApplicationController < ActionController::Base
  include Clearance::Authorization
  protect_from_forgery with: :exception
  decorates_assigned :site

  helper_method :current_user, :signed_in?, :signed_out?

  before_action :set_sentry_raven_context
  before_action :assign_current_user
  before_action :assign_scope
  before_action :assign_title

  rescue_from ReadPermissionsError, with: :not_found
  rescue_from JWT::DecodeError, with: :not_found

  def error_flash_models(models, header)
    flash[:error] = header + "\n" + models.map do |model|
      prefix = block_given? ? ((yield model).to_s + ': ') : ''
      prefix + model.errors.full_messages.to_s
    end.join("\n")
  end

  def current_user
    auth_cookie = cookies['flight_sso']

    return nil unless auth_cookie.present?

    User.from_jwt_token(auth_cookie).tap do |u|

      if u
        clearance_session.sign_in(u)
      else
        clearance_session.sign_out
      end

    end
  end

  def signed_in?
    !current_user.nil?
  end

  def signed_out?
    current_user.nil?
  end

  def sign_out
    clearance_session.sign_out
    cookies.delete('flight_sso', domain: request.host[request.host.index('alces')..-1])
  end

  private

  def clearance_session
    request.env[:clearance]
  end

  def set_sentry_raven_context
    if current_user
      Raven.user_context(
        id: current_user.id,
        email: current_user.email,
        name: current_user.name,
        site: current_user.site&.name,
      )
    end
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

  def assign_current_user
    RequestStore.store[:current_user] = current_user
  end

  def current_site
    @scope.site
  end

  # From https://stackoverflow.com/a/4983354/2620402.
  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def scope_id_param(id_method)
    params[id_method] || params[:id]
  end

  def assign_scope
    return unless current_user

    @scope = case request.path
             when /^\/clusters/
               id = scope_id_param(:cluster_id)
               @cluster = Cluster.find(id)
             when /^\/components/
               id = scope_id_param(:component_id)
               @component = @cluster_part = Component.find(id)
             when /^\/component-groups/
               id = scope_id_param(:component_group_id)
               @component_group = ComponentGroup.find(id)
             when /^\/services/
               id = scope_id_param(:service_id)
               @service = @cluster_part = Service.find(id)
             when /^\/cases/
               begin
                 id = scope_id_param(:case_id)
                 Case.find_from_id!(id).associated_model
               rescue ActiveRecord::RecordNotFound
                 # There are various routes which begin `/cases/` but are not
                 # the route for a particular Case; if we can't find the Case
                 # we must either be in one of these, or we are trying to find
                 # a Case which actually doesn't exist. Either way assign the
                 # Site scope rather than blow up, then carry on and let
                 # specific controller we are in handle this as normal.
                 assign_site_scope
               end
             else
               assign_site_scope
             end
  end

  def assign_site_scope
    if current_user.contact?
      # For a Site contact, the Site in scope is always the Site they belong
      # to.
      @site = current_user.site
    elsif request.path =~ /^\/sites/
      # For an admin viewing the pages for a particular Site, that is the Site
      # in scope.
      id = scope_id_param(:site_id)
      @site = Site.find(id)
    else
      # If we reach this point we must be an admin viewing the top-level pages
      # which show cross-site information, so assign the AllSites scope which
      # handles this in a similar way to any of the other scopes.
      AllSites.new
    end
  end

  def assign_title
    if @scope
      @title = <<~EOF.squish
        #{@scope.readable_model_name.split.map(&:capitalize).join(' ')}
        Dashboard#{@scope.respond_to?(:name) ? ": #{@scope.name}" : ''}
      EOF
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
