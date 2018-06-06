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
    @note = note_from_params
  end

  def create
    cluster = cluster_from_params
    @note = cluster.notes.build(note_params)
    if @note.save
      flash[:success] = 'Notes created'
    else
      flash[:error] = "Your notes were not created: #{format_errors(@note)}"
    end
    redirect_back fallback_location: cluster
  end

  def update
    @note = note_from_params
    if @note.update_attributes(note_params)
      flash[:success] = 'Notes updated'
      redirect_to send("#{@note.flavour}_cluster_notes_path", @note.cluster)
    else
      flash[:error] = "Your notes were not updated: #{format_errors(@note)}"
      render :edit
    end
  end

  private

  def note_from_params(flavour=nil)
    if params[:id]
      note = Note.find(params[:id])
    else 
      cluster = cluster_from_params
      note = cluster.notes.send(flavour).first || cluster.notes.new(flavour: flavour)
    end
    note.decorate
  end

  def cluster_from_params
    Cluster.find(params.require(:cluster_id))
  end

  def note_params
    params.require(:note).permit(:description, :flavour)
  end
end
