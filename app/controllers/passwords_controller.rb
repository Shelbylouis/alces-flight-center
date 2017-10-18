
class PasswordsController < Clearance::PasswordsController
  def reset_complete
    user = find_user_by_id_and_confirmation_token
    new_password = Utils.generate_password(length: 20)

    if user&.update_password(new_password)
      handle_password_reset_success(user: user, new_password: new_password)
    else
      handle_password_reset_failure
    end
  end

  private

  def handle_password_reset_success(user:, new_password:)
    flash[:success] = <<-EOF.squish
      A new password has been generated and emailed to you, and your account
      has been signed in.
    EOF

    sign_in user
    redirect_to root_path
    session[:password_reset_token] = nil

    PasswordsMailer.reset_password_complete(
      user: user, password: new_password
    ).deliver_later
  end

  def handle_password_reset_failure
    flash[:error] = <<-EOF.squish
      The URL you visited is invalid. If you are attempting to reset your
      password you may need to re-enter your email so we can send you a valid
      link.
    EOF
    redirect_to passwords_path
  end
end
