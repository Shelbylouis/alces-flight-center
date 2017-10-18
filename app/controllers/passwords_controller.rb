
class PasswordsController < Clearance::PasswordsController
  def reset_complete
    @user = find_user_by_id_and_confirmation_token
    new_password = Utils.generate_password(length: 20)

    if @user.update_password new_password
      flash[:success] = <<-EOF.squish
        A new password has been generated and emailed to you, and your account
        has been signed in.
      EOF

      sign_in @user
      redirect_to root_path
      session[:password_reset_token] = nil

      PasswordsMailer.reset_password_complete(
        user: @user, password: new_password
      ).deliver_later
    end
  end
end
