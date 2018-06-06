require '<%= File.exists?('spec/rails_helper.rb') ? 'rails_helper' : 'spec_helper' %>'

RSpec.describe <%= class_name %>Policy do
  include_context 'policy'

  let(:record) { nil }

  permissions :some_action? do
    pending "add some examples to (or delete) #{__FILE__}"
  end
end
