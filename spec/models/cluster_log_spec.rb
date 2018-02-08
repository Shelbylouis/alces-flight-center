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
end

