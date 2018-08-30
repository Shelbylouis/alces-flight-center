class CaseMailerPreview < ApplicationMailerPreview
  def new_case
    CaseMailer.new_case(get_case)
  end

  def change_assignee_id
    my_case = get_case
    CaseMailer.change_assignee_id(my_case, nil, User.admins.first.id)
  end

  def change_contact_id
    my_case = get_case
    CaseMailer.change_contact_id(my_case, nil, User.admins.first.id)
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

  def change_request
    CaseMailer.change_request(
      get_case,
      'has text to be replaced with the text from ChangeRequestStateTransitionDecorator.',
      user,
      get_case.email_recipients
    )
  end

  def change_association
    CaseMailer.change_association(get_case, user)
  end

  def resolve_case
    CaseMailer.resolve_case(get_case, user)
  end

  private

  def get_case
    @case_id ? Case.find_from_id!(@case_id) : Case.last
  end
end
