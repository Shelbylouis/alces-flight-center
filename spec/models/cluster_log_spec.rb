require 'rails_helper'

RSpec.describe ClusterLog, type: :model do
  def expect_single_error(model, error_text)
    expect(model).not_to be_valid
    expect(model.errors.size).to eq(1)
    expect(model.errors.full_messages.first).to include(error_text)
  end

  it 'errors without a cluster' do
    log = build(:cluster_log, cluster: nil)
    expect_single_error log, 'Cluster'
  end

  it 'errors without any details' do
    log = build(:cluster_log, details: nil)
    expect_single_error log, 'Details'
  end

  context 'with an invalid engineer' do
    it 'errors without an engineer' do
      log = build(:cluster_log, engineer: nil)
      expect(log).not_to be_valid

      expected_error = 'Engineer must exist'
      actual_errors = log.errors.full_messages.join("\n")
      expect(actual_errors).to include(expected_error)
    end

    it 'errors if the engineer is not an admin' do
      log = build(:cluster_log, engineer: create(:user))
      expect_single_error log, 'admin'
    end
  end

  describe '#cases' do
    subject { create(:cluster_log) }

    def create_case(case_subject)
      kase = create(:case, cluster: subject.cluster, subject: case_subject)
      subject.cases << kase
      subject.reload
    end

    it 'can have multiple cases' do
      case_msgs = ['first', 'second', 'third']
      case_msgs.each { |m| create_case(m) }
      expect(subject).to be_valid
      expect(subject.cases.map(&:subject)).to contain_exactly(*case_msgs)
    end

    it 'validates that all cases belong to its cluster' do
      ['other-case1', 'other-case2', 'other-case3'].each do |case_msg|
        create_case(case_msg)
      end
      other_cluster = create(:cluster, name: 'other-cluster')
      bad_case = create(:case, cluster: other_cluster, subject: 'Bad Case')
      subject.cases << bad_case
      subject.reload
      expect_single_error subject, "#{bad_case.rt_ticket_id}"
    end
  end
end

