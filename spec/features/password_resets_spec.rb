require 'rails_helper'

RSpec.feature 'password reset process', type: :feature do
  it 'a user can go through the full process and receive a new password' do
    new_password = 'verysecure123'
    allow(Utils).to receive(:generate_password).and_return(new_password)

    user = create(
      :user,
      name: 'Fred Flintstone',
      email: 'fred.flint@example.com'
    )

    visit '/reset-password'
    fill_in 'Email', with: user.email

    click_button 'Reset password'
    expect(page).to have_text(
      /You will receive an email within the next few minutes/
    )

    user.reload
    user_reset_complete_path = reset_password_complete_path(
      user_id: user.id,
      token: user.confirmation_token
    )

    reset_start_email = ActionMailer::Base.deliveries.first
    expect(reset_start_email).to have_subject(/Reset your password/)

    # Work around for `have_body_text` expectation failing after updating
    # `mail` Gem; see https://github.com/email-spec/email-spec/issues/202.
    expect(reset_start_email.to_s).to include(user_reset_complete_path)
    # expect(reset_start_email).to have_body_text(
    #   /#{Regexp.escape(user_reset_complete_path)}/
    # )

    visit user_reset_complete_path
    expect(
      find('.alert-success')
    ).to have_text(/your account has been signed in/)

    reset_complete_email = ActionMailer::Base.deliveries.second
    expect(reset_complete_email).to have_subject(/Password successfully reset/)
    expect(reset_complete_email).to have_body_text(/#{new_password}/)
  end

  context 'when invalid/no parameters included in URL' do
    it 'displays error and redirects to start of process' do
      visit reset_password_complete_path(user_id: 'foo')

      expect(current_path).to eq(passwords_path)
      expect(
        find('.alert-danger')
      ).to have_text(/URL.*is invalid/)
    end
  end
end
