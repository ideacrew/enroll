
When(/^Hbx Admin clicks on the Update APTC \/ CSR button$/) do
  click_link "Update APTC / CSR"
end

Then(/^Hbx Admin should see the list of APTC \/ CSR Enrollments and an Edit button$/) do
  expect(page).to have_content('Update APTC / CSR - Search')
  expect(page).to have_content('APTC / CSR Enrollments')
end

When(/^Hbx Admin clicks on the Edit button$/) do
  @family = FactoryGirl.create(:family, :with_primary_family_member)
  tax_household = FactoryGirl.create(:tax_household, household: @family.active_household, effective_ending_on: nil )
  eligibility_determination = FactoryGirl.create(:eligibility_determination, tax_household: tax_household, csr_eligibility_kind: 'csr_100' )
  visit "hbx_admin/edit_aptc_csr?family_id=#{@family.id}&person_id=#{@family.person.id}"
end

Then(/^Hbx Admin should see the edit APTC \/ CSR form for the individual$/) do
  expect(page).to have_content('Editing APTC / CSR for:')
end

Then(/^Hbx Admin should see a text saying there is no Active Enrollment$/) do
  @current_year = TimeKeeper.date_of_record.year
  expect(page).to have_content("No Active Enrollment (Assistance Receiving) for #{@current_year}.")
end

Then(/^Hbx Admin should see APTC and CSR as editable fields$/) do
  expect(page).to have_text("max_aptc")
  expect(page).to have_text("csr_percentage")
end
	