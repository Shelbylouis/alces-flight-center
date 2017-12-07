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
    describe 'every Site-related record defines site for permissions purposes' do
      ActiveRecord::Base.connection.tables.each do |table|
        begin
          klass = table.singularize.camelize.constantize
        rescue NameError
          # Some tables do not have corresponding AR class; we don't care about
          # those.
          next
        end

        globally_available_model = ApplicationRecord::GLOBAL_MODELS.include?(klass)
        next if globally_available_model

        it "site defined for #{klass.to_s}" do
          expect(klass.instance_methods).to include(:site)
        end
      end
    end
  end
end
