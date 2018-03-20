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

    it 'filters out nil elements after map' do
      expect(
        json_map(
          [
            TestObject.new(:not_nil),
            TestObject.new(nil),
          ],
          :property
        )
      ).to eq([:not_nil].to_json)
    end
  end

  describe '#boolean_symbol' do
    it 'gives check when condition is true' do
      expect(boolean_symbol(true)).to eq(raw('&check;'))
    end

    it 'gives cross when condition is false' do
      expect(boolean_symbol(false)).to eq(raw('&cross;'))
    end
  end
end

