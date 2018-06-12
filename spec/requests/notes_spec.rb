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

  describe 'creating a note' do
    let(:flavour) { 'engineering' }
    let(:params) { {note: {description: 'My description'}} }
    let(:path) { cluster_note_path(cluster_without_notes, flavour: flavour, as: user) }
    let(:user) { admin }

    it 'creates the note' do
      expect do
        post path, params: params
      end.to change { Note.count }.by(1)
    end

    it 'creates the note for the given cluster' do
      expect(Note.count).to eq(0)
      post path, params: params
      expect(Note.first.cluster).to eq(cluster_without_notes)
    end

    it 'creates the note with the given description' do
      expect(Note.count).to eq(0)
      post path, params: params
      expect(Note.first.description).to eq('My description')
    end

    it 'creates the note with the given flavour' do
      expect(Note.count).to eq(0)
      post path, params: params
      expect(Note.first.flavour).to eq(flavour)
    end
  end

  describe 'updating a note' do
    let(:note) { engineering_note }
    let(:params) { {note: {description: 'My new description'}} }
    let(:path) { cluster_note_path(note.cluster, note, as: user) }
    let(:user) { admin }

    it 'updates the notes description' do
      expect do
        patch path, params: params
      end.to change { Note.find(note.id).description }.to('My new description')
    end
  end

  describe 'deleting a note' do
    let(:user) { admin }
    it 'when the description is empty it deletes the note' do
      note = engineering_note
      cluster = note.cluster
      path = cluster_note_path(note.cluster, note, as: user)
      expect do
        patch path, params: {note: {description: nil}}
      end.to change { cluster.reload.notes.length }.by(-1)
    end
  end
end
