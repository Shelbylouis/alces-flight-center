class ChangeMotdRequestStateTransition < ApplicationRecord
  belongs_to :change_motd_request
  belongs_to :user

  delegate :site, to: :change_motd_request
end
