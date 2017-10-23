Given(/^a consumer, with a family, exists1$/) do
  consumer :with_nuclear_family_valid_auth
  consumer.person.consumer_role.update_attributes(:ssn_validation => 'verified')
  consumer.person.consumer_role.update_attributes(:native_validation => 'verified')

  consumer.person.consumer_role.update_attributes(:assisted_income_validation => 'verified')

  consumer.person.consumer_role.update_attributes(:assisted_mec_validation => 'verified')
end

Given (/^that a consumer has a Financial Assistance application in the submitted state$/) do
  create_plan
  create_hbx_profile
  application
  application.update_attributes(:assistance_year => TimeKeeper.date_of_record.year)
  application.update_attributes(:aasm_state => 'submitted')

  create_eligibility_determination
  create_assisted_verifications
end

Given(/^that a family member is in any other than Verified verification status for a given data type \(SSN, Citizenship, Income, Native Alaskan\)$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
# consumer.person.consumer_role.update_attributes(:ssn_validation => 'outstanding')
# consumer.person.consumer_role.update_attributes(:native_validation => 'outstanding')
#
# consumer.person.consumer_role.update_attributes(:assisted_income_validation => 'outstanding')
#
# consumer.person.consumer_role.update_attributes(:assisted_mec_validation => 'outstanding')

# click_link 'Families'

end

When(/^the admin navigates to the family “Documents” page$/) do
  login_as hbx_admin, scope: :user
  click_link 'Families'
  wait_for_ajax(10,2)
  family_member = find('a', :text => /\AJohn Smith1\z/)
  family_member.click
end

And(/^visit family and click document$/) do
  login_as hbx_admin, scope: :user
  click_link "Documents"
end

When(/^clicks on the “Choose Action” dropdown$/) do
  wait_for_ajax(10,2)
  verification_insured_families_path
  wait_for_ajax(10,2)

  click_link "Documedkjhsdants"
  # wait_for_ajax(10,2)
  # find_button('Action').visible?
  # find('.person', :text => /\AJohn Smith1\z/).find(:xpath,'.verification-types')

  # find('.v-type-actions').find(:xpath, 'option[2]').select_option
  # find('.verification-types').find(:row, 1).find('.v-type-actions').find(:xpath, 'option[2]').select_option
  # find('.v-type-name', :text => /\AIncome\z/)
  find(:xpath, '//*[@id="home"]/div/div/div[2]/div[2]/div[2]/div/div[1]/div/div[2]/div[7]/div/div[4]/div/div[2]').click
  # find('.verification-process').find(:row,1).find('.family-member').find(:row, 1).find('.verification-types').find(:row, 1).find('.v-type-actions').trigger 'click'
  # find('.v-type-actions').trigger 'click'

  # find('verification_actions').find(:xpath, 'option[2]').select_option

end

Then(/^the admin user will be able to click on the action “Verify”$/) do
  page.should have_xpath('//*[@id="home"]/div/div/div[2]/div[2]/div[2]/div/div[1]/div/div[2]/div[7]/div/div[4]/div/div[3]/div/ul/li[2]')
  # pending # Write code here that turns the phrase above into concrete actions

end

When(/^“Verify” is clicked by admin user$/) do
  wait_for_ajax(10,2)
  find(:xpath,'//*[@id="home"]/div/div/div[2]/div[2]/div[2]/div/div[1]/div/div[2]/div[7]/div/div[4]/div/div[3]/div/ul/li[2]').click
  # visit find(:xpath,'//*[@id="59bc779feab5e79221000000-Income"]/div')


  # pending # Write code here that turns the phrase above into concrete actions
end

Then(/^a field will expand beneath the verification type field presenting the following$/) do
  page.should have_css('.interaction-choice-control-verification-reason')
end

Given(/^that a family member is in the Verified status for a given verification type \(SSN, Citizenship, Income, Native Alaskan\)$/) do

  find('.interaction-choice-control-verification-reason', :text => /\ASelect Reason\z/).click
  select('Document in EnrollApp', :from => 'verification_reason')
  # select('Document in EnrollApp', :from => 'verification_reason').click_link('Confirm')
  find('.v-type-confirm-button').click
  click_link('Conskdjndjfirm')
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^there is an existing verification reason$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the admin user clicks on the action “Verify”$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the admin user selects a new reason$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^clicks “complete”$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the new reason will be stored\.$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^that a family member is in the Outstanding verification status for a given data type \(SSN, Citizenship, Income, Native Alaskan\)$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^the type status will change to the Verified state\.$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

When(/^the family member user navigates to the family “Documents” page$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^family member user can see only verification status for each type$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^not “Choose Action” dropdown will be shown for any family members and verification types$/) do
  pending # Write code here that turns the phrase above into concrete actions
end
