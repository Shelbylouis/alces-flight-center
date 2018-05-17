require 'rails_helper'

RSpec.describe Service, type: :model do
  include_examples 'inheritable_support_type'

  describe 'Advice based and managed services' do
    it_behaves_like 'advice based and managed type'
  end
end
