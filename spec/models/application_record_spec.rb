require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '#readable_model_name' do
    # Create concrete model to test.
    subject { create(:component_group) }

    it 'returns lowercase, human-readable name of model' do
      expect(subject.readable_model_name).to eq 'component group'
    end
  end

  describe '#underscored_model_name' do
    subject { create(:component_group) }

    it 'returns underscored name of model' do
      expect(subject.underscored_model_name).to eq 'component_group'
    end
  end

  describe '#id_param_name' do
    subject { create(:component_group) }

    it 'returns param name which would typically be used for model ID' do
      expect(subject.id_param_name).to eq :component_group_id
    end
  end

  describe 'permissions' do
    def mock_request_user
      allow(Request).to receive(:current_user).and_return(user)
    end

    # These tests ensures that every model is handled for permissions purposes,
    # by either specifying how it is related to a Site (which will be used to
    # enforce that a non-admin User is a contact for that Site in order to
    # access it) or by specifying that it is globally available (and so will be
    # accessible by any User).
    describe 'models should normally be related to a Site xor explicitly globally available' do
      # Eager load app so get all descendants of ApplicationRecord, not just
      # those which happen to already be loaded.
      Rails.application.eager_load!

      ApplicationRecord.descendants.each do |klass|
        # The class is a base class for use in STI; skip it and just its
        # subclasses will be checked.
        next if klass.descendants.present?

        # Users are special, they have a relation with a Site but are also
        # globally available, i.e. able to be read by any other User.
        next if klass == User

        it "#{klass.to_s} has Site xor is global" do
          related_to_site = klass.new.respond_to?(:site)
          is_global = klass.globally_available?
          expect([related_to_site, is_global]).to be_one
        end
      end
    end

    context 'when contact' do
      let :user { create(:contact) }
      let :user_site { user.site }
      let :another_site { create(:site) }

      it 'cannot read model belonging to another Site' do
        model = create(:cluster, site: another_site)
        mock_request_user

        expect do
          Cluster.find(model.id)
        end.to raise_error(ReadPermissionsError)
      end

      it 'can read model belonging to own Site' do
        model = create(:cluster, site: user_site)
        mock_request_user

        expect do
          Cluster.find(model.id)
        end.not_to raise_error
      end
    end
  end
end
