class MaintenanceWindow < ApplicationRecord
  belongs_to :user
  belongs_to :case
  belongs_to :confirmed_by,
    class_name: 'User',
    required: false
end
