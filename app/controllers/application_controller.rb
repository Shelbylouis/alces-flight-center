require 'exceptions'
require 'json_web_token'

class ApplicationController < RootController
  include Pundit

  decorates_assigned :site

  helper_method :signed_in_without_account?
  helper_method :case_url
  helper_method :case_path

  before_action :assign_current_user
  before_action :assign_scope
  before_action :assign_title

  # Ensure actions authorize the resource they operate on (using Pundit). These
  # read-only actions are skipped as, for now at least, whether a User is able
  # to read a record is checked at the model level, and handled as a 404 if
  # they are forbidden; see `ApplicationRecord#check_read_permissions`.
  NO_AUTH_ACTIONS = [:show, :index]
  after_action :verify_authorized, except: NO_AUTH_ACTIONS

  rescue_from ReadPermissionsError, with: :not_found
  rescue_from JWT::DecodeError, with: :not_found

  def error_flash_models(models, header)
    flash[:error] = header + "\n" + models.map do |model|
      prefix = block_given? ? ((yield model).to_s + ': ') : ''
      prefix + model.errors.full_messages.to_s
    end.join("\n")
  end

  def sign_out
    clearance_session.sign_out
    # Matches both `*.alces-flight.com` (for production/staging) and
    # `*.alces-flight.lvh.me` (for development).
    domain = request.host[request.host.index('alces')..-1]
    cookies.delete('flight_sso', domain: domain)
  end

  def signed_in_without_account?
    # A Flight SSO account does not necessarily correspond to a Flight Center
    # account. If someone is logged in to Flight SSO but does not have access to
    # Flight Center then current_user will be nil but they will have a
    # `flight-sso` cookie.
    # We want to identify this scenario so that we can use more appropriate
    # language e.g. don't tell them to "log in" again.
    current_user.nil? && valid_sso_token?
  end

  def case_url(kase)
    cluster_case_url(kase.cluster, kase)
  end

  def case_path(kase)
    cluster_case_path(kase.cluster, kase)
  end

  private

  def valid_sso_token?
    # This method checks that the token itself is valid (and verifies the
    # signature), not that it corresponds to a User.
    cookies['flight_sso'] && JsonWebToken.decode(cookies['flight_sso'])
  rescue JWT::DecodeError
    false
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
               id = scope_id_param(:cluster_id).upcase
               @cluster = Cluster.find_from_id!(id)
             when /^\/components/
               id = scope_id_param(:component_id)
               @component = @cluster_part = Component.find(id)
             when /^\/component-groups/
               id = scope_id_param(:component_group_id)
               @component_group = ComponentGroup.find(id)
             when /^\/services/
               id = scope_id_param(:service_id)
               @service = @cluster_part = Service.find(id)
             else
               assign_site_scope
             end
  end

  def assign_site_scope
    id = scope_id_param(:site_id)
    if current_user.site_user?
      # For a Site user, the Site in scope is always the Site they belong to.
      @site = current_user.site
    elsif request.path =~ /^\/sites/ && id.present?
      # For an admin viewing the pages for a particular Site, that is the Site
      # in scope.
      @site = Site.find(id)
    else
      # If we reach this point we must be an admin viewing the top-level pages
      # which show cross-site information, so assign the AllSites scope which
      # handles this in a similar way to any of the other scopes.
      AllSites.new
    end
  end

  def assign_title
    @title = scope_dashboard_title if @scope
  end

  def scope_dashboard_title
    [
      @scope.readable_model_name.titlecase,
      ' Dashboard',
      @scope.respond_to?(:name) ? ": #{@scope.name}" : '',
    ].join
  end

  def format_errors(model)
    model.errors.messages.map do |field, messages|
      "#{field} #{messages.join(', ')}"
    end.join('; ')
  end
end
