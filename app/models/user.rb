require 'json_web_token'
require 'validates_email_format_of'

class User < ApplicationRecord
  include Clearance::User
  include AdminConfig::User

  ROLES = %w{admin primary_contact secondary_contact viewer}

  belongs_to :site, required: false

  validates_associated :site
  validates :name, presence: true
  validates :email,
            presence: true,
            email_format: { message: Constants::EMAIL_FORMAT_MESSAGE }
  validates :role, presence: true, inclusion: ROLES

  validates :site, {
    presence: {unless: :admin?},
    absence: {if: :admin?}
  }
  validate :validates_primary_contact_assignment

  delegate :admin?,
    :primary_contact?,
    :secondary_contact?,
    :viewer?,
    to: :role_inquiry,
    allow_nil: true

  def contact?
    primary_contact? || secondary_contact?
  end

  # Anyone who isn't just a viewer, i.e. who can perform some edits, is
  # considered an editor.
  def editor?
    !viewer?
  end

  def validates_primary_contact_assignment
    return unless site_primary_contact
    if primary_contact? && site_primary_contact != self
      errors.add(:role, 'primary contact is already set for this site')
    end
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
  end

  def remember_token
    # This is only here for testing purposes (see
    # https://github.com/alces-software/alces-flight-center/pull/152#discussion_r180035530).
    ::JsonWebToken.encode(
      { 'email' => email }
    )
  end

  private

  def role_inquiry
    role&.inquiry
  end

  def site_primary_contact
    @site_primary_contact ||= site&.primary_contact
  end
end
