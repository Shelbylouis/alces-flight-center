require 'rails_helper'

RSpec.describe HasSupportType do
  describe '#readable_support_type' do
    subject do
      Struct.new(:support_type) do
        include HasSupportType
      end
    end

    it 'returns correct value when support_type is `managed`' do
      expect(subject.new('managed').readable_support_type).to eq 'fully managed'
    end

    it 'returns correct value when support_type is `advice`' do
      expect(subject.new('advice').readable_support_type).to eq 'self-managed'
    end

    it 'raises otherwise' do
      expect do
        subject.new('foo').readable_support_type
      end.to raise_error.with_message(/Unknown support type/)
    end
  end
end
