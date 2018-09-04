require 'rails_helper'

RSpec.describe Case, type: :model do
  describe '#valid?' do

    [:component, :service, :cluster].each do |part_name|
      context "with #{part_name}" do
        subject do

          part_key = part_name == :cluster ? :cluster : part_name.to_s.pluralize.to_sym
          part_value = part_name == :cluster ? part : [part]

          build(
            "case_requiring_#{part_name}",
            part_key => part_value,
            tier_level: tier_level
          )
        end

        context 'which is `advice`' do
          let(:part) { create("advice_#{part_name}") }

          context 'when tier_level == 3' do
            let(:tier_level) { 3 }

            it { is_expected.to be_valid }
          end

          context 'when tier_level < 3' do
            let(:tier_level) { 2 }

            it 'should normally be invalid' do
              expect(subject).to be_invalid
              expect(subject.errors.messages).to include(
                part_name => [/is self-managed, only consultancy support may be requested/]
              )
            end

            it 'should be valid when Issue is special' do
              subject.issue.identifier = Issue::IDENTIFIER_NAMES.first

              expect(subject).to be_valid
            end
          end
        end

        context 'which is `managed`' do
          let(:part) { create("managed_#{part_name}") }

          context 'when tier_level < 3' do
            let(:tier_level) { 2 }

            it "should be valid when #{part_name} later switched to `advice`" do
              subject.save!
              part.update!(support_type: :advice)
              subject.reload

              expect(subject).to be_valid
            end
          end
        end
      end
    end
  end
end
