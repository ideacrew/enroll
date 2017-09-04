
Given(/^that the user has FAA Application$/) do
  consumer :with_nuclear_family
  login_as consumer, scope: :user
end

And(/^the user has navigated to the FAA Household Info$/) do
  create_plan
  @application = application
  visit edit_financial_assistance_application_path(@application)
  expect(page).to have_content('Household Info: Family Members')
end

And(/^the system has solved for all possible relationship between household members$/) do
  binding.pry
  find('.interaction-click-control-add-member').click
  fill_in "dependent_first_name", with: 'Jackson'
  fill_in "dependent_last_name", with: 'lee'
  fill_in "family_member_dob_", with: '10/10/1990'
  fill_in "dependent_ssn", with: '123456333'
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[2]/p').click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[3]/div/ul/li[7]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click

  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  find(:xpath, '//label[@for="radio_physically_disabled_no"]').click
  find('#add_info_buttons_ > span').click

  binding.pry


  # find(:xpath, '//*[@id="household_info_add_member"]').click

  
 

  


  # expect(@family.primary_applicant.person.person_relationships).to be nil

  # find('.btn', text: 'CONTINUE').click
  # @family = application.family
  # family_member1 = FactoryGirl.create(:family_member, family: @family)
  # family_member2 = FactoryGirl.create(:family_member, family: @family)
  # @family.family_members << family_member1
  # @family.family_members << family_member2
  # expect(@family.reload.family_members.count). to eq(3)
  # application.populate_applicants_for(@family)
  # application.save
  # family_member1.person.add_relationship(@family.primary_applicant_person, 'unrelated', @family.id)
  # family_member2.person.add_relationship(@family.primary_applicant_person, 'unrelated', @family.id)
  # expect(@family.family_members.map(&:primary_relationship)).to eq(['self', 'unrelated', 'unrelated'])
end

And(/^there is a nil value for at least one relationship$/) do

  find('.interaction-click-control-add-member').click
  fill_in "dependent_first_name", with: 'johnson'
  fill_in "dependent_last_name", with: 'smith'
  fill_in "family_member_dob_", with: '10/10/1984'
  fill_in "dependent_ssn", with: '123456543'
  find(:xpath, '//label[@for="radio_female"]').click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[2]/p').click
  find(:xpath, '//*[@id="new_dependent"]/div[1]/div[4]/div[1]/div/div[3]/div/ul/li[7]').click
  find(:xpath, '//label[@for="is_applying_coverage_true"]').click

  find(:xpath, '//label[@for="dependent_us_citizen_true"]').click
  find(:xpath, '//label[@for="dependent_naturalized_citizen_false"]').click
  find(:xpath, '//label[@for="indian_tribe_member_no"]').click
  find(:xpath, '//label[@for="radio_incarcerated_no"]').click
  find(:xpath, '//label[@for="radio_physically_disabled_no"]').click
  find('#add_info_buttons_ > span').click
  binding.pry
  # matrix = @family.build_relationship_matrix
  # missing_relationships = @family.find_missing_relationships(matrix)
  # expect(missing_relationships.count).to eq(1)

  #expect(@family.primary_applicant.person.person_relationships).to be nil
end

When(/^the user clicks Continue$/) do
  click_link 'Continue'
end

Then(/^the user will navigate to the Household relationships page$/) do
  expect(page).to have_content('Household Info: Family Members')
end

# Then(/^there is a nil value for at least one relationship in page$/) do
#   pending # Write code here that turns the phrase above into concrete actions
# end

Then(/^the CONTINUE button will be disabled$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the user enters nothing in the missing relationship drop down$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^clicks ADD Relationship$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^an error will present reminding the user to populate the relationship$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the user clicks ADD RELATIONSHIP$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the user the user selects a valid relationship in the drop down$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^a confirmation of save will display$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^another relationship pair has a nil value despite the save$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^that value pair will display$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^all relationships have been populated$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^all applicant information is complete$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the user will navigate to the Review Your Application page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end