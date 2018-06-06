class ChangeRequestDecorator < ApplicationDecorator
  delegate_all

  def user_facing_state
    state.tr('_', ' ').titleize
  end
end
