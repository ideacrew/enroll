# frozen_string_literal: true

Given(/^the prevent_concurrent_sessions feature is (.*)?/) do |is_enabled|
  is_enabled == "enabled" ? enable_feature(:prevent_concurrent_sessions) : disable_feature(:prevent_concurrent_sessions)
end

Given(/^the preferred_user_access feature is (.*)?/) do |is_enabled|
  is_enabled == "enabled" ? enable_feature(:preferred_user_access) : disable_feature(:preferred_user_access)
end

# rubocop:disable Style/GlobalVars
Given(/^(.*) logs in on browser (.*)?$/) do |_user, session_id|
  in_session(session_id) do
    person = people["Hbx Admin"] || people["Broker Assisted"]

    session = $sessions[session_id]
    session.visit "/users/sign_in"
    session.fill_in SignIn.username, :with => person[:email]
    session.find('#user_login').set(person[:email])
    session.fill_in SignIn.password, :with => person[:password]
    session.fill_in SignIn.username, :with => person[:email] unless session.find(:xpath, '//*[@id="user_login"]').value == person[:email]
    session.find(SignIn.sign_in_btn, wait: 5).click
  end
end

And(/^(.*) attempts to navigate on browser (.*)?/) do |_user, session_id|
  in_session(session_id) do
    session = $sessions[session_id]
    session.visit exchanges_hbx_profiles_root_path
  end
end

Then(/^(.*) on browser (.*) should (.*) the logged out due to concurrent session message?/) do |_user, session_id, visibility|
  in_session(session_id) do
    session = $sessions[session_id]
    if visibility == "see"
      expect(session).to have_content(l10n('devise.sessions.signed_out_concurrent_session'))
    else
      expect(session).not_to have_content(l10n('devise.sessions.signed_out_concurrent_session'))
    end
  end
end
# rubocop:enable Style/GlobalVars
