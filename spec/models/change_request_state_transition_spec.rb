require 'rails_helper'

RSpec.shared_examples 'it must be initiated by a contact' do
  it 'can be initiated by contact' do
    subject.user = create(:contact)

    expect(subject).to be_valid
  end

  it 'cannot be initiated by admin' do
    subject.user = create(:admin)

    expect(subject).not_to be_valid
    expect(subject.errors.messages).to include user: [/must be a contact/]
  end

  it 'cannot be initiated by viewer' do
    subject.user = create(:viewer)

    expect(subject).not_to be_valid
    expect(subject.errors.messages).to include user: [/must be a contact/]
  end
end


RSpec.describe ChangeRequestStateTransition, type: :model do

  subject do
    build(:change_request_state_transition, event: event, user: user)
  end

  ADMIN_EVENTS = %w(propose handover).freeze
  NON_ADMIN_EVENTS = %w(authorise decline complete).freeze

  let(:event) { 'propose' }
  let(:user) { create(:admin) }
  it { is_expected.to validate_presence_of(:user) }

  ADMIN_EVENTS.each do |event|
    context "when `#{event}` event" do
      let(:event) { event }

      it_behaves_like 'it must be initiated by an admin'
    end
  end

  NON_ADMIN_EVENTS.each do |event|
    context "when `#{event}` event" do
      let(:event) { event }

      it_behaves_like 'it must be initiated by a contact'
    end
  end

  it 'has no events not covered by these tests' do
    states = subject.change_request.state_paths(from: :draft).flatten.map(&:event).map(&:to_s).uniq.sort

    expect(states).to eq( (ADMIN_EVENTS + NON_ADMIN_EVENTS).sort )
  end
end
