require 'rails_helper'

RSpec.describe NotePolicy do
  include_context 'policy'

  context 'when the note is an engineering note' do
    let(:record) { build(:engineering_note) }

    permissions :edit?, :update?, :set_visibility? do
      it_behaves_like 'it is available only to admins'
    end
  end

  context 'when the note is a customer note' do
    let(:record) { build(:customer_note) }

    permissions :create?, :edit?, :update? do
      it_behaves_like 'it is available only to editors'
    end
  end
end
