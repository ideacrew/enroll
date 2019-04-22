Given(/^oustanding verfications users exists$/) do
  person = FactoryGirl.create(:person, :with_consumer_role, :with_active_consumer_role)
  @person_name = person.full_name
  person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
  family = FactoryGirl.create(:family, :with_primary_family_member, person: person)
  enrollment = FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, household: family.active_household, aasm_state: "coverage_selected", kind: "individual", effective_on: TimeKeeper.date_of_record.beginning_of_year)
  enrollment_member = FactoryGirl.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment)
  enrollment.save!
  families = Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.is_any_enrollment_member_outstanding' => true)
end

When(/^Admin clicks Outstanding Verifications$/) do
  page.find('.families.dropdown-toggle.interaction-click-control-families').click
  page.find('.interaction-click-control-outstanding-verifications').trigger('click')
end

When(/^Admin clicks Families tab$/) do
  page.find('.families.dropdown-toggle.interaction-click-control-families').click
  within('.dropdown-menu') do
    find('.interaction-click-control-families').click
  end
end

Then(/^the Admin is navigated to the Families screen$/) do
  expect(page).to have_xpath("//*[@id='inbox']/div/div[1]/h1", text: 'Families')
end

And 'I click on the name of a person of family list' do
  within('table.effective-datatable tbody tr:last-child') do
    find('td.col-name a').trigger('click')
  end
end

Then(/^the Admin is navigated to the Outstanding Verifications screen$/) do
  expect(page).to have_xpath("//div[contains(@class, 'container')]/h1", text: 'Outstanding Verifications')
end


Then(/^the Admin has the ability to use the following filters for documents provided: Fully Uploaded, Partially Uploaded, None Uploaded, All$/) do
  expect(page).to have_xpath('//*[@id="Tab:vlp_partially_uploaded"]', text: 'Partially Uploaded')
  expect(page).to have_xpath('//*[@id="Tab:vlp_fully_uploaded"]', text: 'Fully Uploaded')
  expect(page).to have_xpath('//*[@id="Tab:vlp_none_uploaded"]', text: 'None Uploaded')
  expect(page).to have_xpath('//*[@id="Tab:all"]', text: 'All')
end

Then(/^the Admin is directed to that user's My OPM page$/) do
  page.find(:xpath, "//table[contains(@class, 'effective-datatable')]/tbody/tr/td[1]/a").trigger('click')
  expect(page).to have_content("My OPM")
  expect(page).to have_content("#{@person_name}")
end

