class ChangeRequestStateTransition < ApplicationRecord
  belongs_to :change_request
  belongs_to :user

  delegate :site, to: :change_request

  alias_attribute :requesting_user, :user
end
