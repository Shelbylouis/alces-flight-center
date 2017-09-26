require 'validates_email_format_of'

class Contact < ApplicationRecord
  include Clearance::User

  belongs_to :site
  validates_associated :site
  validates :name, presence: true
  validates :email, email_format: { message: 'is not looking good' }
  validates :password, presence: true, length: { minimum: 5 }
end
