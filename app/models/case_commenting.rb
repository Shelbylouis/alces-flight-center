
class CaseCommenting
  def initialize(kase, user)
    @kase = kase
    @user = user
  end

  def disabled?
    disabled_text.present?
  end

  def disabled_text
    if user.viewer?
      viewer_cannot_comment_message
    elsif !kase.open?
      not_open_message
    elsif kase.issue.administrative? && !user.admin?
      administrative_message
    elsif user.contact? && kase.comments_could_be_enabled? && !kase.comments_enabled
      non_consultancy_message
    else
      ''
    end
  end

  private

  attr_reader :kase, :user

  def viewer_cannot_comment_message
    'As a viewer you cannot comment on cases.'
  end

  def not_open_message
    "Commenting is disabled as this case is #{kase.state}."
  end

  def non_consultancy_message
    <<~MESSAGE.squish
      Additional discussion is not available for this case. If you wish to
      request additional support please either escalate this case, or open a
      new support case.
    MESSAGE
  end

  def administrative_message
    'Commenting is disabled as this is an administrative case.'
  end
end
