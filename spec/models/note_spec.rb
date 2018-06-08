require 'rails_helper'

RSpec.describe Note, type: :model do
  include_examples 'markdown_column', test_nil: false

  describe '#valid?' do
    shared_examples 'note validations' do
      it { is_expected.to validate_presence_of(:flavour) }
      it { is_expected.to validate_inclusion_of(:flavour).in_array(Note::FLAVOURS) }
      it { is_expected.to validate_presence_of(:description) }
      it { is_expected.to belong_to(:cluster) }
      it { is_expected.to have_one(:site) }
    end

    context 'when customer note' do
      subject { create(:customer_note) }
      include_examples 'note validations'
    end

    context 'when engineering note' do
      subject { create(:engineering_note) }
      include_examples 'note validations'
    end
  end

  describe 'funky routing using `flavour` instead of `id`' do
    subject { note.to_param }

    context 'when customer note' do
      let(:note) { create(:customer_note) }
      it { is_expected.to eq('customer') }
    end

    context 'when engineering note' do
      let(:note) { create(:engineering_note) }
      it { is_expected.to eq('engineering') }
    end
  end

  describe 'scope method for each flavour' do
    let(:cluster) { create(:cluster) }

    let(:notes) do
      {
        engineering: create_list(:engineering_note, 2),
        customer: create_list(:customer_note, 2),
      }
    end

    Note::FLAVOURS.each do |flavour|
      it "Note::#{flavour} should return correct notes" do
        expect(Note.send(flavour)).to eq(notes[flavour.to_sym])
      end
    end
  end
end
