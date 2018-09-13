class NotesController < ApplicationController
  decorates_assigned :note

  def show
    @note = note_from_params
    # Authorisation happens in Note#check_read_permissions
    render :new unless @note.persisted?
  end

  def edit
    @note = note_from_params
    authorize @note
  end

  def new
    @note = cluster_from_params.notes.build(
      title: 'New document',
      visibility: 'engineering'
    ).decorate
    authorize @note
  end

  def create
    @note = note_from_params
    authorize @note

    if @note.update_attributes(enforce_visibility(note_params))
      flash[:success] = 'Document created.'
      redirect_to cluster_documents_path(@note.cluster)
    else
      flash[:error] = "Your document was not created: #{format_errors(@note)}"
      redirect_back fallback_location: @note.cluster
    end
  end

  def update
    @note = note_from_params
    authorize @note

    if note_params[:description].blank?
      @note.destroy
      flash[:success] = 'Document deleted.'
      redirect_to cluster_documents_path(@note.cluster)
    elsif @note.update_attributes(enforce_visibility(note_params))
      flash[:success] = 'Document updated.'
      redirect_to @note.decorate.path
    else
      flash[:error] = "Your document was not updated: #{format_errors(@note)}"
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
    if params[:id]
      Note.find(params[:id])
    else
      cluster_from_params.notes.build
    end
  end

  def note_params
    params.require(:note).permit(:description, :title, :visibility)
  end

  def cluster_from_params
    Cluster.find_from_id!(params.require(:cluster_id))
  end

  def enforce_visibility(params)
    params.tap do |p|
      unless policy(@note).set_visibility?
        p[:visibility] = 'engineering'
      end
    end
  end
end
