
class ClearanceMailerPreview < ApplicationMailerPreview
  def change_password
    ClearanceMailer.change_password user
  end
end
