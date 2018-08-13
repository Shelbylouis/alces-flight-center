require 'rails_helper'

RSpec.describe 'alces:deploy:staging:obfuscate_users' do
  include_context 'rake'

  let! :contact do
    create(:contact, name: 'Some Contact', email: 'some.contact.email@example.com')
  end

  let! :admin do
    create(:admin, name: 'Some Admin', email: 'some.admin@example.com')
  end

  it_behaves_like 'it has prerequisite', :environment

  it 'changes contacts to have `center+${local_part}@alces-software.com` emails' do
    subject.invoke

    expect(contact.reload.email).to eq 'center+some.contact.email@alces-software.com'
  end

  it 'does not change admins' do
    admin.reload # So `updated_at` not at precision finer than database will save.
    original_email = admin.email
    orinal_updated_at = admin.updated_at

    subject.invoke

    admin.reload
    expect(admin.email).to eq original_email
    expect(admin.updated_at).to eq(orinal_updated_at)
  end
end
