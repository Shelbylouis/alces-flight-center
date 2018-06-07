class ChangeRequestStateTransitionDecorator < ApplicationDecorator
  def event_card
    text = "#{text_for_event(object.event)} #{cr_link(object)}"
    h.render 'cases/event',
             name: object.user.name,
             date: object.created_at,
             text: text,
             type: 'cog'
  end

  private

  def text_for_event(event)
    case event
    when 'propose'
      'Change request has been proposed and is awaiting customer authorisation.'
    when 'decline'
      'Change request has been declined.'
    when 'authorise'
      'Change request has been authorised.'
    when 'handover'
      'Change request is ready for handover.'
    when 'complete'
      'Change request is now complete.'
    end
  end

  def cr_link(crst)
    kase = crst.change_request.case

    h.link_to(
       'View change request',
       h.cluster_case_change_request_path(
         kase.cluster,
         kase,
         crst.change_request
       ),
       class: 'btn btn-secondary float-right'
    )
  end
end
