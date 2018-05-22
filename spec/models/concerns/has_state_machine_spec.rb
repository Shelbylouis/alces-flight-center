require 'rails_helper'

RSpec.describe HasStateMachine do
  class MockStateMachineModel
    include HasStateMachine

    state_machine initial: :first_state do
      state :first_state
      state :second_state

      event(:some_event) { transition first_state: :second_state }
      event(:another_event) { transition second_state: :first_state }
    end
  end

  subject do
    MockStateMachineModel.new
  end

  describe '#events' do
    it 'gives all possible events' do
      expect(MockStateMachineModel.events).to match_array([
        :another_event,
        :some_event,
      ])
    end
  end

  describe '#possible_states' do
    it 'gives all possible states' do
      expect(MockStateMachineModel.possible_states).to match_array([
        :first_state,
        :second_state,
      ])
    end
  end

  describe '#state_enum' do
    it 'gives possible states to be picked up by admin interface' do
      expect(subject.state_enum).to eq(MockStateMachineModel.possible_states)
    end
  end
end
