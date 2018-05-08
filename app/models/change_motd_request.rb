class ChangeMotdRequest < ApplicationRecord
  validates_presence_of :motd
  belongs_to :case

  delegate :site, to: :case
end
