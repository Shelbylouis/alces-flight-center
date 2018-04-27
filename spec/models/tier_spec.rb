require 'rails_helper'

RSpec.describe Tier, type: :model do
  it { is_expected.to validate_presence_of(:fields) }
  it { is_expected.to validate_presence_of(:level) }

  it do
    is_expected.to validate_numericality_of(:level)
      .only_integer
      .is_greater_than_or_equal_to(0)
      .is_less_than_or_equal_to(3)
  end

  describe '#valid?' do
    let :issue { create(:issue) }

    before :each do
      create(:tier, issue: issue, level: 1)
    end

    context 'when issue already has tier with same level' do
      subject do
        build(:tier, issue: issue, level: 1)
      end

      it 'should be invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.messages).to match(
          level: [/issue already has tier at this level/]
        )
      end
    end

    context 'when unrelated issue already has tier with same level' do
      subject do
        build(:tier, level: 1)
      end

      it { is_expected.to be_valid }
    end
  end

  describe '#case_form_json' do
    subject do
      create(
        :tier,
        id: 1,
        level: 2,
        fields: [{
          type: 'input',
          name: 'Some field',
          optional: true,
        }]
      )
    end

    it 'gives correct JSON' do
      expect(subject.case_form_json).to eq(
        id: 1,
        level: 2,
        fields: subject.fields,
      )
    end
  end
end
