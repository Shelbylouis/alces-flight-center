class CaseMailerPreview < ApplicationMailerPreview
  def new_case
    CaseMailer.with(case: get_case).new_case
  end

  def comment
    my_comment = CaseComment.first || FactoryBot.build(:case_comment)
    CaseMailer.with(comment: my_comment).comment
  end

  def maintenance
    CaseMailer.with(
      case: get_case,
      text: 'This text will be replaced with the text from MaintenanceNotifier'
    ).maintenance
  end

  private

  def get_case
    Case.first || FactoryBot.build(
        :case,
        created_at: DateTime.now
    )
  end
end
