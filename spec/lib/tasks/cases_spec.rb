require 'rails_helper'

RSpec.describe 'alces:cases:auto_archive' do
  include_context 'rake'

  before :each do
    create(:case, id: 0, last_known_ticket_status: 'resolved', completed_at: 3.weeks.ago, archived: false)
    create(:case, id: 1, last_known_ticket_status: 'deleted', completed_at: 2.weeks.ago, archived: false)
    create(:case, id: 2, last_known_ticket_status: 'open', completed_at: 3.weeks.ago, archived: false)
    create(:case, id: 3, last_known_ticket_status: 'rejected', completed_at: 1.weeks.ago, archived: false)
  end

  it_behaves_like 'it has prerequisite', :environment

  it 'archives cases with tickets completed more than two weeks ago' do

    subject.invoke

    expect(Case.find(0).archived).to be(true)  # Easy case
    expect(Case.find(1).archived).to be(true)  # On the edge of 2 weeks; 'deleted' is a completed state
    expect(Case.find(2).archived).to be(false)  # Old but still open
    expect(Case.find(3).archived).to be(false)  # Too recent to archive

  end

  describe 'logging' do
    let(:logger) { Rails.logger }

    before :each do
      expect(ActiveSupport::Logger).to receive(:new).with(
        'log/tasks/cases/auto_archive.log',
        'weekly',
      ).and_return(logger)
      allow(logger).to receive(:info)
    end

    it 'logs when task started' do
      expect(logger).to receive(:info).with(
        "#{task_name} running at #{DateTime.current.iso8601}"
      )

      subject.invoke
    end

    it 'logs each case archival' do
      expect(logger).to receive(:info).with(/Archiving case 0.*/)
      expect(logger).to receive(:info).with(/Archiving case 1.*/)

      subject.invoke
    end
  end
end
