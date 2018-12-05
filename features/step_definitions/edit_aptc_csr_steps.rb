
Then (/^Hbx Admin sees Families link$/) do
  expect(page).to have_text("Families")
end

When(/^Hbx Admin clicks on Families link$/) do
  click_link "Families"
end

if Settings.aca.state_abbrevation == "DC"
  Then(/^Hbx Admin should see an Edit APTC \/ CSR link$/) do
    find_link('Edit APTC / CSR').visible?
  end
end

if Settings.aca.state_abbrevation == "MA"
  Then(/^Hbx Admin should not see an Edit APTC \/ CSR link$/) do
    expect(page).to_not have_text("Edit APTC / CSR")
  end
end
