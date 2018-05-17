class CaseDecorator < ApplicationDecorator
  delegate_all

  def user_facing_state
    model.state.to_s.titlecase
  end

  def case_select_details
    [
      "#{display_id} #{subject}",
      created_at.to_formatted_s(:long),
      associated_model.name,
      "Created by #{user.name}"
    ].join(' | ')
  end

  def association_info
    associated_model.decorate.links
  end

  def case_link
    h.link_to(display_id, h.case_path(self), title: subject)
  end

  def chargeable_symbol
    h.boolean_symbol(chargeable)
  end

  def tier_description
    h.tier_description(tier_level)
  end

  def commenting_disabled?
    commenting_disabled_text.present?
  end

  def commenting_disabled_text
    if !open?
      "Commenting is disabled as this case is #{state}."
    elsif current_user.contact? && !consultancy?
      <<~TITLE.squish
            This is a non-consultancy support case and so additional discussion is
            not available. If you wish to request additional support please either
            escalate this case (which may incur a charge), or open a
            new support case.
      TITLE
    end
  end
end
