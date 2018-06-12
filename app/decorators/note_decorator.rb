class NoteDecorator < ApplicationDecorator
  delegate_all

  def subtitle
    if current_user.admin?
      "#{flavour.capitalize} notes"
    else
      "Cluster notes"
    end
  end

  def new_form_intro
    if current_user.admin?
      "There are currently no #{flavour} notes for this cluster. You may add
      them below."
    else
      "There are currently no notes for this cluster. You may add them below."
    end
  end

  def edit_form_intro
    if current_user.admin?
      "Edit the #{flavour} notes for this cluster below."
    else
      'Edit your cluster notes below.'
    end
  end

  def path
    h.cluster_note_path(cluster, self)
  end

  def edit_path
    h.edit_cluster_note_path(cluster, self)
  end

  def form_path
    [note.cluster, note]
  end
end
