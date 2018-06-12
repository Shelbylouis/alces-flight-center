require 'rails_helper'

RSpec.describe LogDecorator do
  describe '#event_card' do
    subject do
      log.decorate.event_card
    end
    let(:log) { create(:log_with_markdown_details) }

    it "contains the log's rendered details" do
      expect(subject).to include(log.rendered_details)
    end

    it "contains engineer's name" do
      expect(subject).to include(log.engineer.name)
    end

    it "contains log's creation date" do
      expect(subject).to include(log.created_at.to_formatted_s(:long))
    end
  end
end
