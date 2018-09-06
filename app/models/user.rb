require 'json_web_token'
require 'validates_email_format_of'

class User < ApplicationRecord
  include Clearance::User
  include AdminConfig::User

  ROLES = %w{admin primary_contact secondary_contact viewer}

  ROLES.each do |role|
    scope role.pluralize, -> { where(role: role) }
  end

  belongs_to :site, required: false

  has_many :engineer_cases, class_name: 'Case', foreign_key: :assignee
  has_many :contact_cases, class_name: 'Case', foreign_key: :contact

  validates_associated :site
  validates :name, presence: true
  validates :email,
            presence: true,
            email_format: { message: Constants::EMAIL_FORMAT_MESSAGE }
  validates :role, presence: true, inclusion: ROLES

  validates :site, {
    presence: {if: :site_user?},
    absence: {if: :admin?}
  }
  validate :validates_primary_contact_assignment

  validate :validates_viewer_case_assignment
  before_save :reassign_cases_if_necessary
  after_save :forget_changed_role

  delegate :admin?,
    :primary_contact?,
    :secondary_contact?,
    :viewer?,
    to: :role_inquiry,
    allow_nil: true

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting role.
  def role_enum
    ROLES
  end

  def contact?
    primary_contact? || secondary_contact?
  end

  # Anyone who isn't just a viewer, i.e. who can perform some edits, is
  # considered an editor.
  def editor?
    !viewer?
  end

  def site_user?
    !admin?
  end

  def self.globally_available?
    true
  end

  def self.from_jwt_token(token)
    claims = ::JsonWebToken.decode(token)  # handles signature verification too
    user = find_by_email(claims.fetch('email'))

    user.tap do |u|
      # If we want to update local values with those given in the token, do the following:
      #  u.name = claims.fetch('username')
      #  u.save
    end
  rescue JWT::DecodeError
    # Either the token isn't syntactically valid (not Base64-encoded valid JSON)
    # or else signature verification failed (fraudulent token, or staging token
    # being used in production or vice versa).
    nil
  end

  def remember_token
    # This is only here for testing purposes (see
    # https://github.com/alces-software/alces-flight-center/pull/152#discussion_r180035530).
    ::JsonWebToken.encode(
      { 'email' => email }
    )
  end

  def assigned_cases
    engineer_cases.empty? ? contact_cases : engineer_cases
  end

  def role=(new_role)
    if role != new_role
      @role_changed = true
    end
    super(new_role)
  end

  private

  def role_inquiry
    role&.inquiry
  end

  def site_primary_contact
    @site_primary_contact ||= site&.primary_contact
  end

  def password_optional?
    true  # since we use SSO for passwords
  end

  def reassign_cases_if_necessary
    if @role_changed && viewer? && assigned_cases.any?
      assigned_cases.each do |kase|
        kase.contact = site_primary_contact
        kase.save!
        CaseMailer.reassigned_case(kase, self, site_primary_contact)
      end
    end
  end

  def forget_changed_role
    @role_changed = false
  end

  def validates_primary_contact_assignment
    return unless site_primary_contact
    if primary_contact? && site_primary_contact != self
      errors.add(:role, 'primary contact is already set for this site')
    end
  end

  def validates_viewer_case_assignment
    # If we have just been changed to be a viewer, then don't run this validation
    # as we've yet to reassign the cases elsewhere.
    # We should only be doing that before_save (not before validation) since it
    # should only happen if the user's role is actually changed (and saved).
    return if @role_changed && viewer?
    errors.add(:cases, 'must be empty for a viewer') if viewer? && assigned_cases.any?
  end
end
