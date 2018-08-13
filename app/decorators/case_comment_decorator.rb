class CaseCommentDecorator < ApplicationDecorator
  delegate_all

  def event_card
    h.render 'cases/event',
             name: object.user.name,
             date: object.created_at,
             text: object.rendered_text,
             formatted: true,
             type: 'comment-o',
             details: 'Comment'
  end

  def preview_path
    h.preview_case_case_comments_path(self.case)
  end

  def write_path
    h.write_case_case_comments_path(self.case)
  end

  def form_path
    [self.case, self]
  end
end
