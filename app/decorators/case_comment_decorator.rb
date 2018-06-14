class CaseCommentDecorator < ApplicationDecorator

  def event_card
    h.render 'cases/event',
             name: object.user.name,
             date: object.created_at,
             text: object.rendered_text,
             formatted: true,
             type: 'comment-o',
             details: 'Comment'
  end

end
