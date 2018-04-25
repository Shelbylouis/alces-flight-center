require 'rails_helper'

RSpec.describe Case, type: :model do
  describe '#valid?' do
    [:component, :service, :cluster].each do |part_name|
      context "when associated with `advice` #{part_name}" do
        subject do
          build(
            "case_requiring_#{part_name}",
            part_name => part,
            tier_level: tier_level
          )
        end

        let :part { create("advice_#{part_name}") }

        context 'when tier_level == 3' do
          let :tier_level { 3 }

          it { is_expected.to be_valid }
        end

        context 'when tier_level < 3' do
          let :tier_level { 2 }

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
    end
  end
end
