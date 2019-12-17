# frozen_string_literal: true

And(/^.+ visits the Edit Broker Applicant page for (.*?) of agency (.*?)$/) do |broker_name, legal_name|
  broker_role = assign_broker_to_broker_agency(broker_name, legal_name)
  person = broker_role.person
  url = "/exchanges/broker_applicants/#{person.id}/edit"
  visit(url)
end

And(/^.+ edits the broker application and clicks update$/) do
  # This page was unable to update in the past
  click_button('Update')
end

Then(/^.+should see a success message that the broker application was successfully updated$/) do
  expect(page).to have_content("Broker applicant successfully updated.")
end
