require 'rails_helper'

RSpec.describe CaseCommentDecorator do
  describe '#event_card' do
    subject do
      case_comment.decorate.event_card
    end
    let(:case_comment) { create(:case_comment_with_markdown_text) }

    it "contains the case comment's rendered text" do
      expect(subject).to include(case_comment.rendered_text)
    end

    it "contains user's name" do
      expect(subject).to include(case_comment.user.name)
    end

    it "contains case comment's creation date" do
      expect(subject).to include(case_comment.created_at.to_formatted_s(:long))
    end
  end
end
