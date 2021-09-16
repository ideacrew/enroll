And(/^Hbx Admin should see broker application with carrier appointments$/) do
  if Settings.aca.broker_carrier_appointments_enabled
    find_all("[id^=person_broker_role_attributes_carrier_appointments_]").each do |checkbox|
      checkbox.should be_checked
    end
    expect(page).to have_text(l10n("broker_carrier_appointments_enabled_note", site_long_name: site_long_name))
  end
end

And(/^Admin clicks on the pending button$/) do
  find('.interaction-click-control-broker-pending').click
end

Then(/^Hbx Admin views a successful message$/) do
  expect(page).to have_content('Broker applicant is now pending.')
end
