
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
    elsif user.contact? && !kase.consultancy?
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
      Additional discussion is not available for cases in the current support
      tier. If you wish to request additional support please either escalate
      this case (which may incur a charge), or open a new support case.
    MESSAGE
  end
end
