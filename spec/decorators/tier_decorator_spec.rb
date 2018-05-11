require 'rails_helper'

RSpec.describe TierDecorator do
  describe '#case_form_json' do
    subject do
      build(
        :tier,
        id: 1,
        level: 2,
        fields: nil,
        tool: nil,
      ).decorate
    end

    context 'when Tier with `fields`' do
      before :each do
        subject.fields = [{
          type: 'input',
          name: 'Some field',
          optional: true,
        }]
      end

      it 'gives correct JSON' do
        expect(subject.case_form_json).to eq(
          id: 1,
          level: 2,
          fields: subject.fields,
        )
      end
    end

    context 'when Tier with `tool`' do
      before :each do
        subject.tool = 'motd'
      end

      it 'gives correct JSON' do
        expect(subject.case_form_json).to eq(
          id: 1,
          level: 2,
          tool: 'motd'
        )
      end
    end
  end
end
