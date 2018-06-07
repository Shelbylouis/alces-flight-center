class NotesController < ApplicationController
  decorates_assigned :note

  def show
    @note = note_from_params
    if @note.persisted?
      render :show
    else
      render :new
    end
  end

  def edit
    @note = note_from_params
  end

  def create
    @note = note_from_params
    if @note.update_attributes(note_params)
      flash[:success] = 'Notes created'
    else
      flash[:error] = "Your notes were not created: #{format_errors(@note)}"
    end
    redirect_back fallback_location: @note.cluster
  end

  def update
    @note = note_from_params
    if @note.update_attributes(note_params)
      flash[:success] = 'Notes updated'
      redirect_to cluster_note_path(@note.cluster, flavour: @note.flavour)
    else
      flash[:error] = "Your notes were not updated: #{format_errors(@note)}"
      render :edit
    end
  end

  private

  def note_from_params
    cluster = cluster_from_params
    flavour = params.require(:flavour)
    note = cluster.notes.send(flavour).first || cluster.notes.new(flavour: flavour)
    note.decorate
  end

  def cluster_from_params
    Cluster.find(params.require(:cluster_id))
  end

  def note_params
    params.require(:note).permit(:description)
  end
end
