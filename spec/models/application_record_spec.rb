require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '#readable_model_name' do
    # Create concrete model to test.
    subject { create(:component_group) }

    it 'returns lowercase, human-readable name of model' do
      expect(subject.readable_model_name).to eq 'component group'
    end
  end

  describe 'permissions' do
    def mock_request_user
      allow(Request).to receive(:current_user).and_return(user)
    end

    # This test ensures that every model is handled for permissions purposes,
    # by either specifying how it is related to a Site (which will be used to
    # enforce that a non-admin User is a contact for that Site in order to
    # access it) or by specifying that it is globally available (and so will be
    # accessible by any User).

    describe 'regular models should be related to a Site xor explicitly globally available' do

      ActiveRecord::Base.connection.tables.each do |table|
        begin
          klass = table.singularize.camelize.constantize

          # Irregular models:
          # Users: have a relation with a Site but are also global
          # Expansion: is a base class for STI and is neither
          irregular_models = [User, Expansion]

          next if irregular_models.include? klass
        rescue NameError
          # Some tables do not have corresponding AR class; we don't care about
          # those.
          next
        end

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
