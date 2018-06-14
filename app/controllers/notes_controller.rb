class NotesController < ApplicationController
  decorates_assigned :note

  def show
    @note = note_from_params
    render :new unless @note.persisted?
  end

  def edit
    @note = note_from_params
    authorize @note
  end

  def create
    @note = note_from_params
    authorize @note

    if @note.update_attributes(note_params)
      flash[:success] = 'Notes created'
    else
      flash[:error] = "Your notes were not created: #{format_errors(@note)}"
    end
    redirect_back fallback_location: @note.cluster
  end

  def update
    @note = note_from_params
    authorize @note

    if note_params[:description].blank?
      @note.destroy
      flash[:success] = 'Notes removed'
      redirect_to cluster_path(@note.cluster)
    elsif @note.update_attributes(note_params)
      flash[:success] = 'Notes updated'
      redirect_to @note.decorate.path
    else
      flash[:error] = "Your notes were not updated: #{format_errors(@note)}"
      render :edit
    end
  end

  def preview
    @note = note_from_params
    authorize @note, @note.persisted? ? :edit? : :new?
    @note.description = note_params[:description]

    render layout: false
  end

  def write
    @note = note_from_params
    authorize @note, @note.persisted? ? :edit? : :new?
    @note.description = note_params[:description]

    render layout: false
  end

  private

  def note_from_params
    flavour = params.require(:flavour)
    @cluster.notes.send(flavour).first || @cluster.notes.new(flavour: flavour)
  end

  def note_params
    params.require(:note).permit(:description)
  end
end
