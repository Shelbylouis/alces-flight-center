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
      "No #{flavour} notes have been addded yet."
    else
      "No notes have been addded yet."
    end
  end
end
