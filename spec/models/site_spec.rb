require 'rails_helper'
require 'shared_examples/canonical_name'

RSpec.describe Site, type: :model do
  include_examples 'canonical_name'
end
