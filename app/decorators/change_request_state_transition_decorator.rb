class ChangeRequestStateTransitionDecorator < ApplicationDecorator
  def event_card
    text = text_for_event(object.event)
    h.render 'cases/event',
             name: object.user.name,
             date: object.created_at,
             text: text,
             type: 'cog'
  end

  private

  def text_for_event(event)
    case event
    # TODO this is placeholder text
    when 'propose'
      'Propose.'
    when 'decline'
      'Decline.'
    when 'authorise'
      'Authorise.'
    when 'handover'
      'Handover.'
    when 'complete'
      'Complete.'
    end
  end
end
