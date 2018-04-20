class CaseMailerPreview < ApplicationMailerPreview
  def new_case
    CaseMailer.new_case(get_case)
  end

  def comment
    my_comment = CaseComment.first || FactoryBot.build_stubbed(:case_comment)
    CaseMailer.comment(my_comment)
  end

  def maintenance
    CaseMailer.maintenance(
      get_case,
      'This text will be replaced with the text from MaintenanceNotifier'
    )
  end

  private

  def get_case
    Case.first || FactoryBot.build(
        :case,
        created_at: DateTime.now
    )
  end
end
