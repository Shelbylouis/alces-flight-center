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

  describe '#render_tab_bar' do
    subject { render_tab_bar }

    # It has to return a string. Returning nil breaks the render
    def expect_render_tabs(template)
      expect(helper).to \
        receive(:render).with(template, instance_of(Hash))
                        .once.and_return('')
    end

    context 'without a scope set' do
      before :each { @scope = nil }

      it 'nothing is rendered' do
        expect_render_tabs('partials/card')
        subject
      end
    end

    context 'within a cluster scope' do
      let :cluster { create(:cluster) }
      before :each { @scope = cluster }

      it 'renders the cluster nav bar' do
        expect_render_tabs('partials/tabs')
        subject
      end
    end
  end
end

