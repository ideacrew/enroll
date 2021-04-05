# frozen_string_literal: true

And(/^at least a household members exist$/) do
  click_link "Add New Person"

  fill_in 'applicant[first_name]', :with => 'johnson'
  fill_in 'applicant[last_name]', :with => 'smith'
  fill_in 'jq_datepicker_ignore_applicant[dob]', :with => '10/10/1984'
  click_outside_datepicker("#{l10n('family_information')}")
  fill_in 'applicant[ssn]', :with => '123456543'
  find("span", :text => "choose").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'Spouse')]").click
  find(:xpath, '//label[@for="radio_male"]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click
  choose('radio_incarcerated_no', allow_label_click: true)
  choose('indian_tribe_member_yes', allow_label_click: true)
  choose('applicant_us_citizen_true', allow_label_click: true)
  choose('applicant_naturalized_citizen_false', allow_label_click: true)
  sleep 1
end

Then(/^the user clicks on confirm member$/) do
  find(".btn", text: "CONFIRM MEMBER").click
end

Then(/^the user Should see an error message for Tribal Id$/) do
  expect(page).to have_content("If you selected that you're a member of an American Indian or Alaska Native Tribe, you must enter your Tribal ID")
end