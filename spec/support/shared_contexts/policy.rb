
RSpec.shared_context 'policy' do
  subject { described_class }

  let(:admin) { create(:admin) }
  let(:site_contact) { create(:contact, site: site) }
  let(:site_viewer) { create(:viewer, site: site) }
  let(:site) { create(:site) }
end

RSpec.shared_examples 'it is available only to editors' do
  it 'grants access to admin' do
    expect(subject).to permit(admin, record)
  end

  it 'grants access to site contact' do
    expect(subject).to permit(site_contact, record)
  end

  it 'denies access to site viewer' do
    expect(subject).not_to permit(site_viewer, record)
  end
end

RSpec.shared_examples 'it is available only to admins' do
  it 'grants access to admin' do
    expect(subject).to permit(admin, record)
  end

  it 'denies access to site contact' do
    expect(subject).not_to permit(site_contact, record)
  end

  it 'denies access to site viewer' do
    expect(subject).not_to permit(site_viewer, record)
  end
end

RSpec.shared_examples 'it is available only to contacts' do
  it 'denies access to admin' do
    expect(subject).not_to permit(admin, record)
  end

  it 'grants access to site contact' do
    expect(subject).to permit(site_contact, record)
  end

  it 'denies access to site viewer' do
    expect(subject).not_to permit(site_viewer, record)
  end
end
