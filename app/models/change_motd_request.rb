class ChangeMotdRequest < ApplicationRecord
  validates_presence_of :motd, :state
  belongs_to :case
  has_many :change_motd_request_state_transitions

  delegate :site, to: :case
end
