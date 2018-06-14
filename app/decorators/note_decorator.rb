class NoteDecorator < ApplicationDecorator
  delegate_all

  def subtitle
    if h.current_user.admin?
      "#{flavour.capitalize} notes"
    else
      "Cluster notes"
    end
  end

  def new_form_intro
    if h.current_user.admin?
      "There are currently no #{flavour} notes for this cluster. You may add
      them below.".squish
    elsif h.current_user.contact?
      "There are currently no notes for this cluster. You may add them below."
    elsif h.current_user.viewer?
      "There are currently no notes for this cluster."
    else
      raise_as_unhandled
    end
  end

  def edit_form_intro
    if h.current_user.admin?
      "Edit the #{flavour} notes for this cluster below."
    elsif h.current_user.contact?
      'Edit your cluster notes below.'
    else
      # Viewers are the only other role at the moment, and they cannot access
      # the edit notes page.
      raise_as_unhandled
    end
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
