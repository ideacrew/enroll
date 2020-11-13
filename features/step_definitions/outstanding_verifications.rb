Given(/^oustanding verfications users exists$/) do
  people = [["Aaron", "Anderson"], ["Zach", "Zackary"]]
  @person_names = []
  people.each do |name_hash|
    person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: name_hash[0], last_name: name_hash[1])
    @person_names << person.full_name
    person.consumer_role.update_attributes!(aasm_state: "verification_outstanding")
    family = FactoryBot.create(:family, :with_primary_family_member, person: person)
    issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
    product = FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile)
    enrollment = FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      family => family,
      :household => family.active_household,
      :aasm_state => 'coverage_selected',
      :is_any_enrollment_member_outstanding => true,
      :kind => 'individual',
      :product => product,
      :effective_on => TimeKeeper.date_of_record.beginning_of_year
    )
    FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment)
    enrollment.save!
    Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.is_any_enrollment_member_outstanding' => true)
  end
end

Given(/^one fully uploaded person exists$/) do
  name_hash = ["Michael", "Fox"]
  @fully_verified_names = []
  person = FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role, first_name: name_hash[0], last_name: name_hash[1])
  @fully_verified_names << person.full_name
  person.consumer_role.update_attributes!(aasm_state: "fully_verified")
  family = FactoryBot.create(:family, :with_primary_family_member, person: person)
  issuer_profile = FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)
  product = FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: 'aca_individual', issuer_profile: issuer_profile)
  enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members,
                                 :family => family,
                                 :household => family.active_household,
                                 :aasm_state => 'coverage_selected',
                                 :is_any_enrollment_member_outstanding => true,
                                 :kind => 'individual',
                                 :product => product,
                                 :effective_on => TimeKeeper.date_of_record.beginning_of_year)
  FactoryBot.create(:hbx_enrollment_member, applicant_id: family.primary_applicant.id, eligibility_date: (TimeKeeper.date_of_record - 2.months), hbx_enrollment: enrollment)
  enrollment.save!
  family.update_attributes!(vlp_documents_status: "Fully Uploaded")
  expect(Family.vlp_fully_uploaded.last).to eq(family)
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
  find('a', :text => /First*/i).click
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

And(/^Admin clicks the Fully Uploaded filter and does not see results$/) do
  fully_uploaded = page.all('div').detect { |div| div[:id] == 'Tab:vlp_fully_uploaded' }
  fully_uploaded.click
  # TODO: This stopped working
  sleep 10
  @person_names.each do |person_name|
    expect(page).to_not have_content(person_name)
  end
end

And(/^Admin clicks the Fully Uploaded filter and only sees fully uploaded results$/) do
  expect(Family.vlp_fully_uploaded.count).to eq(1)
  fully_uploaded = page.all('div').detect { |div| div[:id] == 'Tab:vlp_fully_uploaded' }
  fully_uploaded.click
  sleep 10
  # Not fully uploaded
  @person_names.each do |person_name|
    expect(page).to_not have_content(person_name)
  end
  # Fully uploaded
  @fully_verified_names.each do |person_name|
    expect(page).to have_content(person_name)
  end
end

And(/^Admin clicks All and sees all of the results$/) do
  all_people = page.all('div').detect { |div| div[:id] == 'Tab:all' }
  all_people.click
  sleep 5
  @person_names.each do |person_name|
    expect(page).to have_content(person_name)
  end
end

And(/^Admin clicks Documents Uploaded and sorts results by documents uploaded$/) do
  documents_uploaded_sort = page.all('th').detect { |th| th[:class] == 'col-string col-documents_uploaded sorting' }
  documents_uploaded_sort.click
  sleep 5
end


And(/^Admin clicks Name and sorts results by name$/) do
  # Name: activate to sort column descending
  name_sort = page.all('th').detect { |th| th[:class] == 'col-string col-name sorting' }
  name_sort.click
  sleep 5
  # A name will appear here first
  name_sort = page.all('th').detect { |th| th[:class] == 'col-string col-name sorting_asc' }
  name_sort.click
  sleep 5
  # Z name will appear here first
end

Then(/^the Admin is directed to that user's My DC Health Link page$/) do
  # First person name
  click_link @person_names[0]
  expect(page).to have_content("My DC Health Link")
  expect(page).to have_content(@person_names[0])
end

