require 'rails_helper'

RSpec.describe Hash do
  describe 'extensions' do
    describe '#to_struct' do
      subject {{foo: 3, bar: 5}.to_struct}

      it { is_expected.to  have_attributes(foo: 3, bar: 5) }
    end
  end
end
