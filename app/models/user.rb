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
  validates :password, length: { minimum: 5 }, if: :password
  validates :role, presence: true, inclusion: ROLES

  validates :site, {
    presence: {if: :contact?},
    absence: {if: :admin?}
  }
  validates :primary_contact, {
    inclusion: {in: [true, false], if: :contact?},
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

  def validates_primary_contact_assignment
    return unless site_primary_contact
    if primary_contact? && site_primary_contact != self
      errors.add(:role, 'primary contact is already set for this site')
    end
  end

  def self.globally_available?
    true
  end

  private

  def role_inquiry
    role&.inquiry
  end

  def site_primary_contact
    @site_primary_contact ||= site&.primary_contact
  end
end
