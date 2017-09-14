class Contact < ApplicationRecord
  validates :name, presence: true
  validates :email, email_format: { message: 'is not looking good' }
  validates :username, presence: true
  validates :password, presence: true, length: { minimum: 5 }
end
