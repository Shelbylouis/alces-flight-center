require 'validates_email_format_of'

class User < ApplicationRecord
  include Clearance::User
  include AdminConfig

  # If more fields need to be added to User which are just for contact or admin
  # users (as well as site which is just for contacts), then we should split
  # these out to new tables which are conditionally associated with users.
  belongs_to :site, required: false

  validates_associated :site
  validates :name, presence: true
  validates :email, email_format: { message: "must be in format 'a@b.co'" }
  validates :password, presence: true, length: { minimum: 5 }

  validates :site, {
    :presence => {if: :contact?},
    :absence => {if: :admin?}
  }

  alias_attribute :admin?, :admin

  def contact?
    !admin?
  end
end
