# frozen_string_literal: true

Given(/^the prevent_concurrent_sessions feature is (.*)?/) do |is_enabled|
  is_enabled == "enabled" ? enable_feature(:prevent_concurrent_sessions) : disable_feature(:prevent_concurrent_sessions)
end

Given(/^(.*) logs in on browser (.*)?$/) do |_user, session_id|
  using_session(session_id) do
    person = people["Hbx Admin"] || people["Broker Assisted"]

    visit "/users/sign_in"
    fill_in SignIn.username, :with => person[:email]
    find('#user_login').set(person[:email])
    fill_in SignIn.password, :with => person[:password]
    fill_in SignIn.username, :with => person[:email] unless find(:xpath, '//*[@id="user_login"]').value == person[:email]
    find(SignIn.sign_in_btn, wait: 5).click
  end
end

And(/^(.*) attempts to navigate on browser (.*)?/) do |_user, session_id|
  using_session(session_id) do
    visit exchanges_hbx_profiles_root_path
  end
end

Then(/^(.*) on browser (.*) should (.*) the logged out due to concurrent session message?/) do |_user, session_id, visibility|
  using_session(session_id) do
    if visibility == "see"
      expect(page).to have_content(l10n('devise.failure.session_limited'))
    else
      expect(page).not_to have_content(l10n('devise.failure.session_limited'))
    end
  end
end