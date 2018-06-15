class ChangeRequestDecorator < ApplicationDecorator
  delegate_all

  def user_facing_state
    state.titleize
  end
end
