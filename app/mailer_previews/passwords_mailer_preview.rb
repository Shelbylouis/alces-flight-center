
class PasswordsMailerPreview < ApplicationMailerPreview
  def reset_password_complete
    fake_new_password = Utils.generate_password(length: 20)
    PasswordsMailer.reset_password_complete(
      user: user, password: fake_new_password
    )
  end
end
