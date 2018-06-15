class CaseMailerPreview < ApplicationMailerPreview
  def new_case
    CaseMailer.new_case(get_case)
  end

  def change_assignee
    my_case = get_case
    CaseMailer.change_assignee(my_case, user)
  end

  def comment
    my_comment = CaseComment.first || FactoryBot.build_stubbed(:case_comment)
    CaseMailer.comment(my_comment)
  end

  def maintenance
    CaseMailer.maintenance_state_transition(
      get_case,
      'This text will be replaced with the text from MaintenanceNotifier'
    )
  end

  private

  def get_case
    @case_id ? Case.find_from_id!(@case_id) : Case.last
  end
end
