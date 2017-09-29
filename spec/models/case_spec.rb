require 'rails_helper'

RSpec.describe Case, type: :model do
  describe '#mailto_url' do
    it 'creates correct mailto URL' do
      cluster = Cluster.new(name: 'somecluster')
      case_category = CaseCategory.new(name: 'New user request')
      rt_ticket_id = 12345

      support_case = described_class.new(
        cluster: cluster,
        case_category: case_category,
        rt_ticket_id: rt_ticket_id,
      )

      expected_subject = URI.escape(
        'RE: [helpdesk.alces-software.com #12345] Supportware ticket: somecluster - New user request'
      )
      expected_mailto_url = "mailto:support@alces-software.com?subject=#{expected_subject}"
      expect(support_case.mailto_url).to eq expected_mailto_url
    end
  end
end
