# frozen_string_literal: true

# rubocop:disable Style/GlobalVars
Given(/^admin logs in on browser (.*)?/) do |session_id|
  in_session(session_id) do
    person = people["Hbx Admin"]

    session = $sessions[session_id]
    session.visit "/users/sign_in"
    session.fill_in SignIn.username, :with => person[:email]
    session.find('#user_login').set(person[:email])
    session.fill_in SignIn.password, :with => person[:password]
    session.fill_in SignIn.username, :with => person[:email] unless session.find(:xpath, '//*[@id="user_login"]').value == person[:email]
    session.find(SignIn.sign_in_btn, wait: 5).click
  end
end

And(/^admin attempts to navigate on browser (.*)?/) do |session_id|
  in_session(session_id) do
    session = $sessions[session_id]
    session.visit exchanges_hbx_profiles_root_path
  end
end

Then(/^admin on browser (.*) should see the logged out due to concurrent session message?/) do |session_id|
  in_session(session_id) do
    session = $sessions[session_id]
    expect(session).to have_content(l10n('devise.sessions.signed_out_concurrent_session'))
  end
end
# rubocop:enable Style/GlobalVars
