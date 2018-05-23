
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

  # Automatically picked up by rails_admin so only these options displayed when
  # selecting state.
  def state_enum
    self.class.possible_states
  end
end
