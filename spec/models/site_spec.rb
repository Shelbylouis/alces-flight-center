require 'rails_helper'
require 'shared_examples/canonical_name'
require 'shared_examples/markdown_description'

RSpec.describe Site, type: :model do
  include_examples 'canonical_name'
  include_examples 'markdown_description'
end
