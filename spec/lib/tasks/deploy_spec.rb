require 'rails_helper'

RSpec.describe 'alces:deploy:staging:obfuscate_user_data' do
  include_context 'rake'

  let! :contact do
    create(:contact, name: 'Some Contact', email: 'some.contact.email@example.com')
  end

  let! :admin do
    create(:admin, name: 'Some Admin', email: 'some.admin@example.com')
  end

  before :each do
    ENV['STAGING_PASSWORD'] = staging_password
  end

  let :staging_password { 'password123' }

  it_behaves_like 'it has prerequisite', :environment

  it 'changes contacts to have `center+${local_part}@alces-software.com` emails' do
    subject.invoke

    expect(contact.reload.email).to eq 'center+some.contact.email@alces-software.com'
  end

  it 'sets contact passwords to STAGING_PASSWORD environment variable' do
    subject.invoke

    new_email = contact.reload.email
    expect(
      User.authenticate(new_email, staging_password)
    ).to eq(contact)
  end

  it 'aborts and does not change anything if STAGING_PASSWORD not set' do
    ENV.delete('STAGING_PASSWORD')

    expect do
      subject.invoke
    end.to raise_error(/STAGING_PASSWORD environment variable must be set/)
  end

  it 'does not change admins' do
    admin.reload # So `updated_at` not at presision finer than database will save.
    original_email = admin.email
    orinal_updated_at = admin.updated_at

    subject.invoke

    admin.reload
    expect(admin.email).to eq original_email
    expect(admin.updated_at).to eq(orinal_updated_at)
  end
end
