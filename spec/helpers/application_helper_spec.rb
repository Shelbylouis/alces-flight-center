require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#json_map' do
    TestObject = Struct.new(:property)

    it 'maps given function over enumerable, then converts result to JSON' do
      expect(
        json_map(
          [
            TestObject.new('one'),
            TestObject.new('two'),
          ],
          :property
        )
      ).to eq(['one', 'two'].to_json)
    end
  end
end
