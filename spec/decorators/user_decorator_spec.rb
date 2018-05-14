require 'rails_helper'

RSpec.describe UserDecorator do
  describe '#info' do
    subject do
      build(
        :admin,
        name: 'Lord Adminus',
        email: 'adminus@example.com'
      ).decorate
    end

    it 'renders name, and email as HTML link' do
      expect(subject.info).to eq 'Lord Adminus (<a href="mailto:adminus@example.com">adminus@example.com</a>)'
    end

  end
end
