class FlightDirectoryConfig < ApplicationRecord
  include AdminConfig::FlightDirectoryConfig

  belongs_to :site

  validates :hostname, presence: true
  validates :username, presence: true
end
