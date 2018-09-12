class CaseStateTransitionDecorator < ApplicationDecorator
  def event_card
    text, icon = properties_for_event(object.event)
    h.render 'cases/event',
       name: object.user.name,
       date: object.created_at,
       text: text,
       type: icon,
       details: 'Case Transition'
  end

  private

  def properties_for_event(event)
    case event
    when 'resolve'
      return 'This case was marked as resolved.', 'check-circle-o'
    when 'reopen'
      return 'This case was reopened.', 'times-circle-o'
    when 'close'
      return 'This case was closed.', 'lock'
    end
  end
end
