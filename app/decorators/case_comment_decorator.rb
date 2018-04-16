class CaseCommentDecorator < ApplicationDecorator

  def event_card
    h.render 'cases/event',
             name: object.user.name,
             date: object.created_at,
             text: object.text
  end

end
