class ChangeRequestStateTransition < ApplicationRecord
  belongs_to :change_request
  belongs_to :user

  alias_attribute :requesting_user, :user
end
