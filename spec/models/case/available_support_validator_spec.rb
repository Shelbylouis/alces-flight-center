require 'rails_helper'

RSpec.describe Case, type: :model do
  describe '#valid?' do
    [:component, :service, :cluster].each do |part_name|
      context "when associated with `advice` #{part_name}" do
        subject do
          build("case_requiring_#{part_name}", part_name => part)
        end

        let :part { create("advice_#{part_name}") }

        it 'is invalid when tier_level < 3' do
          subject.tier_level = 2

          expect(subject).to be_invalid
          expect(subject.errors.messages).to include(
            part_name => [/is self-managed, only consultancy support may be requested/]
          )
        end

        it 'is valid when tier_level == 3' do
          subject.tier_level == 3

          expect(subject).to be_valid
        end

        it 'is valid when tier_level < 3 and Issue is special' do
          subject.tier_level = 2
          subject.issue.identifier = Issue::IDENTIFIER_NAMES.first

          expect(subject).to be_valid
        end
      end
    end
  end
end
