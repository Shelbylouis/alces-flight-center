class NotesController < ApplicationController
  decorates_assigned :note

  def engineering
    @note = note_from_params(:engineering)
    render :show
  end

  def customer
    @note = note_from_params(:customer)
    render :show
  end

  private

  def note_from_params(flavour)
    cluster = Cluster.find(params.require(:cluster_id))
    note = cluster.notes.send(flavour).first || cluster.notes.new(flavour: flavour)
    @note = note.decorate
  end
end
