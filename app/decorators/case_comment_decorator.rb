class CaseCommentDecorator < ApplicationDecorator

  def event_card
    h.render 'case_comments/case_comment', comment: object
  end

end
