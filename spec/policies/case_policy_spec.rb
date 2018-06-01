require 'rails_helper'

RSpec.describe CasePolicy do
  subject { described_class }

  let(:admin) { create(:admin) }
  let(:site_contact) { create(:contact, site: site) }
  let(:site_viewer) { create(:viewer, site: site) }
  let(:kase) { create(:case, cluster: create(:cluster, site: site)) }
  let(:site) { create(:site) }

  permissions :index?, :resolved? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, kase)
    end

    it 'grants access to site contact' do
      expect(subject).to permit(site_contact, kase)
    end

    it 'grants access to site viewer' do
      expect(subject).to permit(site_viewer, kase)
    end
  end

  permissions :create?, :new?, :escalate? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, kase)
    end

    it 'grants access to site contact' do
      expect(subject).to permit(site_contact, kase)
    end

    it 'denies access to site viewer' do
      expect(subject).not_to permit(site_viewer, kase)
    end
  end

  permissions :close?, :assign?, :resolve?, :set_time? do
    it 'grants access to admin' do
      expect(subject).to permit(admin, kase)
    end

    it 'denies access to site contact' do
      expect(subject).not_to permit(site_contact, kase)
    end

    it 'denies access to site viewer' do
      expect(subject).not_to permit(site_viewer, kase)
    end
  end
end
