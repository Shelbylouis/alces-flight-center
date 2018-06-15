require 'rails_helper'

RSpec.describe NoteDecorator do
  before :each do
    allow(h).to receive(:current_user).and_return(current_user)
  end

  let :note do
    build_stubbed(:note, flavour: flavour).decorate
  end
  let(:flavour) { :$flavour }

  describe '#new_form_intro' do
    subject { note.new_form_intro }

    context 'as an admin' do
      let(:current_user) { build_stubbed(:admin) }

      it do
        is_expected.to eq(
          <<~TEXT.squish
            There are currently no #{flavour} notes for this cluster. You may
            add them below.
          TEXT
        )
      end
    end

    context 'as a contact' do
      let(:current_user) { build_stubbed(:contact) }

      it do
        is_expected.to eq(
          <<~TEXT.squish
            There are currently no notes for this cluster. You may add them
            below.
          TEXT
        )
      end
    end
  end

  describe '#edit_form_intro' do
    subject { note.edit_form_intro }

    context 'as an admin' do
      let(:current_user) { build_stubbed(:admin) }

      it do
        is_expected.to eq(
          "Edit the #{flavour} notes for this cluster below."
        )
      end
    end

    context 'as a contact' do
      let(:current_user) { build_stubbed(:contact) }

      it do
        is_expected.to eq(
          'Edit your cluster notes below.'
        )
      end
    end
  end
end
