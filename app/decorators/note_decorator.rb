class NoteDecorator < ApplicationDecorator
  delegate_all

  def subtitle
    title
  end

  def path
    h.cluster_note_path(cluster, self)
  end

  def edit_path
    h.edit_cluster_note_path(cluster, self)
  end

  def preview_path
    h.preview_cluster_note_path(cluster, self)
  end

  def write_path
    h.write_cluster_note_path(cluster, self)
  end

  def form_path
    [note.cluster, note]
  end

  private

  def raise_as_unhandled
    raise "Don't know how to handle this user"
  end
end
