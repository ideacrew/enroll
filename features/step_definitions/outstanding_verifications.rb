Given(/^oustanding verfications users exists$/) do
  person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role)
  @person_name = person.full_name
  person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
  family = FactoryBot.create(:family, :with_primary_family_member, person: person)
  issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
  product = FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile)
  rating_area = FactoryBot.create(:benefit_markets_locations_rating_area)
  enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                 :family => family,
                                 :household => family.active_household,
                                 :aasm_state => 'coverage_selected',
                                 :is_any_enrollment_member_outstanding => true,
                                 :kind => 'individual',
                                 :product => product,
                                 :rating_area_id => rating_area.id,
                                 :effective_on => TimeKeeper.date_of_record.beginning_of_year)
  FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment)
  enrollment.save!
  Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.is_any_enrollment_member_outstanding' => true)
end

When(/^Admin clicks Outstanding Verifications$/) do
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., 'Families')]", :wait => 10).click
  page.find('.interaction-click-control-outstanding-verifications').click
end

When(/^Admin clicks Families tab$/) do
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., 'Families')]", :wait => 10).click
  find('li', :text => 'Families', :class => 'tab-second', :wait => 10).click
end

Then(/^the Admin is navigated to the Families screen$/) do
  expect(page).to have_selector 'h1', text: 'Families'
end

And 'I click on the name of a person of family list' do
  person = HbxEnrollment.first.family.primary_person
  first_enrolled_primary_person_name = person.full_name
  find('a', :text => first_enrolled_primary_person_name).click
end

And(/I click the name of (.*) from family list/) do |named_person|
  find('a', :text => named_person).click
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

Then(/^the Admin is directed to that user's My DC Health Link page$/) do
  page.find(:xpath, "//table[contains(@class, 'effective-datatable')]/tbody/tr/td[1]/a").click
  expect(page).to have_content("My DC Health Link")
  expect(page).to have_content("#{@person_name}")
end

