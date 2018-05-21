
module HasStateMachine
  extend ActiveSupport::Concern

  included do
    class << self
      def events
        state_machine.events.keys
      end

      def possible_states
        state_machine.states.keys
      end
    end
  end
end
