require 'validates_email_format_of'

class AdditionalContact < ApplicationRecord
  belongs_to :site

  validates :email,
            presence: true,
            email_format: { message: Constants::EMAIL_FORMAT_MESSAGE }
end
