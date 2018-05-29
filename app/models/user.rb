require 'validates_email_format_of'

class User < ApplicationRecord
  include Clearance::User
  include AdminConfig::User

  belongs_to :site, required: false

  validates_associated :site
  validates :name, presence: true
  validates :email,
            presence: true,
            email_format: { message: Constants::EMAIL_FORMAT_MESSAGE }
  validates :password, presence: true, length: { minimum: 5 }

  validates :site, {
    presence: {if: :contact?},
    absence: {if: :admin?}
  }
  validates :primary_contact, {
    inclusion: {in: [true, false], if: :contact?},
    absence: {if: :admin?}
  }
  validate :validates_primary_contact_assignment

  alias_attribute :primary_contact?, :primary_contact

  alias_attribute :admin?, :admin

  def contact?
    !admin?
  end

  def secondary_contact?
    contact? && !primary_contact?
  end

  def validates_primary_contact_assignment
    return if site&.primary_contact.nil?
    errors.add(:primary_contact, 'is already set for this site') if
      primary_contact && site.primary_contact != self
  end

  def self.globally_available?
    true
  end
end
