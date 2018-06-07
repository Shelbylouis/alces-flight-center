require 'rails_helper'

RSpec.describe NotesController, type: :request do
  let(:contact) { create(:contact, site: site) }
  let(:admin) { create(:admin) }
  let(:site) { create(:site) }
  let!(:cluster) { create(:cluster, site: site) }
  let!(:cluster_without_notes) { create(:cluster, site: site) }
  let(:engineering_note) { create(:engineering_note, cluster: cluster) }
  let(:customer_note) { create(:customer_note, cluster: cluster) }

  describe 'permitted routes' do
    context 'when no user' do
      let(:user) { nil }

      it 'does not permit access to engineering notes' do
        note = engineering_note
        path = cluster_note_path(note.cluster, note, as: user)
        expect{get(path)}.to raise_error(ActionController::RoutingError)
      end

      it 'does not permit access to customer notes' do
        note = customer_note
        path = cluster_note_path(note.cluster, note, as: user)
        expect{get(path)}.to raise_error(ActionController::RoutingError)
      end
    end

    context 'when user is site contact' do
      let(:user) { contact }

      it 'does not permit access to engineering notes' do
        note = engineering_note
        path = cluster_note_path(note.cluster, note, as: user)
        expect{get(path)}.to raise_error(ActionController::RoutingError)
      end

      it 'permits access to customer notes' do
        note = customer_note
        path = cluster_note_path(note.cluster, note, as: user)
        get path
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is admin' do
      let(:user) { admin }

      it 'permits access to engineering notes' do
        note = engineering_note
        path = cluster_note_path(note.cluster, note, as: user)
        get path
        expect(response).to have_http_status(:ok)
      end

      it 'permits access to customer notes' do
        note = customer_note
        path = cluster_note_path(note.cluster, note, as: user)
        get path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'show' do
    let(:user) { admin }
    context 'when note exists' do
      it 'shows the note' do
        note = engineering_note
        path = cluster_note_path(note.cluster, note, as: user)
        get path
        expect(response).to render_template(:show)
      end
    end

    context 'when note does not exist' do
      it 'shows a new note form' do
        path = cluster_note_path(cluster_without_notes, flavour: 'engineering', as: user)
        get path
        expect(response).to render_template(:new)
      end
    end
  end
end
