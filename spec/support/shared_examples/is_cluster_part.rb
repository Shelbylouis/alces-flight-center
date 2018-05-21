
RSpec.shared_examples 'it is ClusterPart' do
  include_examples 'inheritable_support_type'
  it_behaves_like 'it has scopes to get advice and managed parts'
end
