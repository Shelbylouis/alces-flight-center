require 'validates_email_format_of'

class Contact < ApplicationRecord
  belongs_to :site
  validates :name, presence: true
  validates :email, email_format: { message: 'is not looking good' }
  validates :username, presence: true
  validates :password, presence: true, length: { minimum: 5 }
end
