require 'rails_helper'

RSpec.describe PolicyDependentOptions do
  describe '.wrap' do
    subject do
      described_class.wrap(
        options,
        policy: policy,
        action_description: action_description,
        user: user
      )
    end

    let(:options) {{ class: 'some-class', title: 'Some Title' }}
    let(:user) { build_stubbed(:user) }
    let(:action_description) { 'fly' }

    context 'when policy is false' do
      let(:policy) { false }

      it 'adds `disabled` attribute to options' do
        expect(subject[:disabled]).to be true
      end

      it 'adds `onclick` attribute to options' do
        expect(subject[:onclick]).to eq('return false;')
      end

      it 'creates and adds `title` attribute to options' do
        role = 'squirrel'
        allow(user).to receive(:role).and_return(role)

        expect(subject[:title]).to eq(
          "As a #{role} you cannot #{action_description}"
        )
      end

      context 'when options contain `class` attribute with array value' do
        let(:options) {{class: class_array}}
        let(:class_array) {['some-class', 'another-class']}

        it 'adds `disabled` class to array' do
          expect(subject[:class]).to eq(
            class_array + ['disabled']
          )
        end
      end

      context 'when options contain class attribute with string value' do
        let(:options) {{class: class_string}}
        let(:class_string) { 'some-class another-class' }

        it 'converts class attribute to array with `disabled` value' do
          expect(subject[:class]).to eq(
            [class_string, 'disabled']
          )
        end
      end
    end

    context 'when policy is true' do
      let(:policy) { true }

      it 'returns the same options' do
        expect(subject).to eq(options)
      end
    end
  end
end
