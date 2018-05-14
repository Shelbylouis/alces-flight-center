class PasswordsMailer < ApplicationMailer
  def reset_password_complete(user, password)
    @user = user
    @password = password
    mail(
      to: @user.email,
      subject: '[Alces Flight Center] Password successfully reset'
    )
  end
end
