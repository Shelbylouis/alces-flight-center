require 'exceptions'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Every model in app is assumed to be related to a specific Site, unless it
  # is explicitly defined as global by adding it to this whitelist.
  GLOBAL_MODELS = [
    AssetRecordFieldDefinition,
    CaseCategory,
    ComponentType,
    Issue,
    ServiceType,
  ]


  after_find :check_read_permissions

  delegate :current_user, to: Request

  def readable_model_name
    self.class.to_s.tableize.humanize(capitalize: false).singularize
  end

  private

  def check_read_permissions
    return if permissions_check_unneeded?

    unless current_user.site_id == site.id
      raise ReadPermissionsError,
        <<-EOF.squish
          User #{current_user.name} (site_id: #{current_user.site_id}) forbidden
          from accessing #{model_identifier} (site_id: #{site.id})
      EOF
    end
  end

  def permissions_check_unneeded?
    return true if globally_available_model?

    # Users can always access themselves and other Users.
    return true if self.class == User

    # `current_user` will be unset either when we're in a web request but no
    # User is logged in or we are not in a web request; in the former case
    # nothing can be exposed already due to routing contraints, and in the
    # latter case since we have no User we don't need to perform any
    # permissions checks.
    return true unless current_user

    # Admins can do anything.
    return true if current_user.admin?
  end

  def model_identifier
    respond_to?(:name) ? "#{readable_model_name} #{name}" : to_s
  end

  def globally_available_model?
    GLOBAL_MODELS.include?(self.class)
  end
end
