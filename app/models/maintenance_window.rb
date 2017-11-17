class MaintenanceWindow < ApplicationRecord
  belongs_to :user
  belongs_to :case
end
