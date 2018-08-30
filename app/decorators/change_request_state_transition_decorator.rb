class ChangeRequestStateTransitionDecorator < ApplicationDecorator
  def event_card
    text = "Change request #{text_for_event} #{cr_link}"
    h.render 'cases/event',
             name: object.user.name,
             date: object.created_at,
             text: text,
             type: 'cog',
             details: 'Change Request Event'
  end

  def text_for_event
    case object.event
    when 'propose'
      'has been proposed and is awaiting customer authorisation.'
    when 'decline'
      'has been declined.'
    when 'authorise'
      'has been authorised.'
    when 'handover'
      'is ready for handover.'
    when 'complete'
      'is now complete.'
    when 'cancel'
      'has been cancelled.'
    when 'request_changes'
      'has had further changes requested.'
    end
  end

  def article_for_event
    case object.event
    when 'propose'
      'A'
    else
      'The'
    end
  end

  private

  def cr_link
    kase = object.change_request.case

    h.link_to(
       'View change request',
       h.cluster_case_change_request_path(
         kase.cluster,
         kase
       ),
       class: 'btn btn-secondary float-right'
    )
  end
end
