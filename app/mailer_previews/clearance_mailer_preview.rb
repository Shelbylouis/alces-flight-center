
class ClearanceMailerPreview
  def change_password
    ClearanceMailer.change_password user
  end

  private

  def user
    # `@user_id` comes from `user_id` URL parameter, if given.
    @user_id ? User.find(@user_id) : mock_user
  end

  def mock_user
    FactoryGirl.build(
      :user,
      id: 9001,
      name: 'Some User',
      email: 'some.user@example.com',
      confirmation_token: '123456'
    )
  end
end
