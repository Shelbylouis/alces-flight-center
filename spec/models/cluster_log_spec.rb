require 'rails_helper'

RSpec.describe ClusterLog, type: :model do
  def expect_single_error(model, error_text)
    expect(model).not_to be_valid
    expect(model.errors.size).to eq(1)
    expect(model.errors.full_messages.first).to include(error_text)
  end

  it 'errors without an engineer' do
    log = build(:cluster_log, engineer: nil)
    expect_single_error log, 'Engineer'
  end

  it 'errors without a cluster' do
    log = build(:cluster_log, cluster: nil)
    expect_single_error log, 'Cluster'
  end

  it 'errors without any details' do
    log = build(:cluster_log, details: nil)
    expect_single_error log, 'Details'
  end
end

