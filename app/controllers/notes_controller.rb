class NotesController < ApplicationController
  decorates_assigned :note

  def engineering
    @note = note_from_params(:engineering)
    if @note.persisted?
      render :show
    else
      render :new
    end
  end

  def customer
    @note = note_from_params(:customer)
    if @note.persisted?
      render :show
    else
      render :new
    end
  end

  def edit
    @note = Note.find(params[:id])
  end

  def create
    cluster = cluster_from_params
    @note = cluster.notes.build(note_params)
    if @note.save
      flash[:success] = 'Notes created'
    else
      error_flash_models [@note], "Your notes were not created. #{@note.errors.full_messages.join('; ').strip}"
    end
    redirect_back fallback_location: cluster
  end

  def update
    @note = Note.find(params[:id])
    if @note.update_attributes(note_params)
      flash[:success] = 'Notes updated'
      redirect_to send("#{@note.flavour}_cluster_notes_path", @note.cluster)
    else
      error_flash_models [@note], "Your notes were not updated. #{@note.errors.full_messages.join('; ').strip}"
      render :edit
    end
  end

  private

  def note_from_params(flavour)
    cluster = cluster_from_params
    note = cluster.notes.send(flavour).first || cluster.notes.new(flavour: flavour)
    @note = note.decorate
  end

  def cluster_from_params
    Cluster.find(params.require(:cluster_id))
  end

  def note_params
    params.require(:note).permit(:description, :flavour)
  end
end
