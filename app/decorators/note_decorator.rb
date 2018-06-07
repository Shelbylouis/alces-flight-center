class NoteDecorator < ApplicationDecorator
  delegate_all

  def subtitle
    if !persisted?
      not_found_message
    elsif current_user.admin?
      "#{flavour.capitalize} notes"
    else
      "Notes"
    end
  end

  def not_found_message
    if current_user.admin?
      "No #{flavour} notes have been added yet."
    else
      "No notes have been added yet."
    end
  end

  def edit_path
    h.edit_cluster_note_path(cluster, object, flavour: flavour)
  end
end
