require 'rails_helper'

RSpec.describe Log, type: :model do
  def expect_single_error(model, error_text)
    expect(model).not_to be_valid
    expect(model.errors.size).to eq(1)
    expect(model.errors.full_messages.first).to include(error_text)
  end

  it 'errors without a cluster' do
    log = build(:log, cluster: nil)
    expect_single_error log, 'Cluster'
  end

  it 'errors without any details' do
    log = build(:log, details: nil)
    expect_single_error log, 'Details'
  end

  context 'with an invalid engineer' do
    it 'errors without an engineer' do
      log = build(:log, engineer: nil)

      log.valid? # Required otherwise the errors haven't been generated
      expected_error = 'Engineer must exist'
      actual_errors = log.errors.full_messages.join("\n")

      expect(log).not_to be_valid
      expect(actual_errors).to include(expected_error)
    end

    it 'errors if the engineer is not an admin' do
      log = build(:log, engineer: create(:user))
      expect_single_error log, 'admin'
    end
  end

  describe '#cases' do
    subject { create(:log) }

    def create_case(case_subject)
      kase = create(:case, cluster: subject.cluster, subject: case_subject)
      subject.cases << kase
      subject.reload
    end

    it 'can have multiple cases' do
      case_subs = ['first', 'second', 'third']
      case_subs.each { |m| create_case(m) }
      expect(subject).to be_valid
      expect(subject.cases.map(&:subject)).to contain_exactly(*case_subs)
    end

    it 'validates that all cases belong to its cluster' do
      other_cluster = create(:cluster, name: 'other-cluster')
      bad_case = create(:case, cluster: other_cluster, subject: 'Bad Case')

      create_case('perfectly normal case')
      subject.cases << bad_case
      subject.reload

      expect_single_error subject, "#{bad_case.rt_ticket_id}"
    end
  end

  it 'does not require a component' do
    expect(create(:log).component).to be_nil
  end

  context 'with a component' do
    let :cluster { create(:cluster) }

    # This spec can not use a factory for creating a new component log
    # as it will implicitly set the cluster and cause the test to fail
    it 'can have a component which sets the cluster' do
      component = create(:component, cluster: cluster)
      log = Log.create(component: component, engineer: create(:admin))
      expect(log.component).to eq(component)
      expect(log.cluster).to eq(cluster)
    end

    it 'errors if the component is in a different cluster' do
      component = create(:component, cluster: create(:cluster))
      log = build(:log, cluster: cluster, component: component)
      expect_single_error log, 'cluster'
    end
  end
end

