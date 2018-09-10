require 'rails_helper'

RSpec::Matchers.define :file_contents do |expected|
  match { |actual| File.read(actual) == File.read(expected) }
end

RSpec.describe 'Cluster documents', type: :feature do
  let(:cluster) { create(:cluster) }

  before(:each) do
    visit cluster_documents_path(cluster, as: user)
  end

  context 'when user is admin' do
    let(:user) { create(:admin) }

    let(:textfile) { Rails.root + 'spec/fixtures/test-upload.txt' }

    it 'allows upload to S3' do

      expect(Cluster::DocumentsHandler).to \
        receive(:store).with(
          'test-upload.txt',
          file_contents(textfile),
          cluster.documents_path
        ).and_return(true)

      attach_file 'Or upload a document:', textfile
      click_button 'Upload'

      expect(find('.alert-success')).to have_text('Document uploaded.')
    end

    it 'gracefully handles S3 errors' do
      expect(Cluster::DocumentsHandler).to \
        receive(:store).and_raise(Aws::S3::Errors::ServiceError.new(nil, 'You can\'t handle the truth'))

      attach_file 'Or upload a document:', textfile
      click_button 'Upload'

      expect(find('.alert-danger')).to have_text('You can\'t handle the truth')
    end

  end

  RSpec.shared_examples 'no upload form' do
    it 'does not show upload form' do
      expect do
        find('#cluster_document')
      end.to raise_exception Capybara::ElementNotFound
    end
  end

  context 'when user is contact' do
    let(:user) { create(:contact, site: cluster.site) }

    include_examples 'no upload form'
  end

  context 'when user is viewer' do
    let(:user) { create(:viewer, site: cluster.site) }

    include_examples 'no upload form'
  end


end
