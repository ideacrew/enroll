Given(/^that the consumer has navigated to the AUTH & CONSENT page$/) do
	visit 'insured/consumer_role/ridp_agreement'
end

When(/^the consumer selects “I Disagree”$/) do
		find(:xpath, '//label[@for="agreement_disagree"]').click
end

When(/^the consumer clicks CONTINUE$/) do
	click_link "Continue"
end

Then(/^the consumer will be directed to the DOCUMENT UPLOAD page$/) do
	expect(page).to have_content('Identity')
	expect(page).to have_content('Application')
end

Given(/^that the consumer has “Disagreed” to AUTH & CONSENT$/) do
	visit 'insured/consumer_role/ridp_agreement'
	find(:xpath, '//label[@for="agreement_disagree"]').click
	click_link "Continue"
end

And(/^the consumer is on the DOCUMENT UPLOAD page$/) do
	expect(page).to have_content('Identity')
	expect(page).to have_content('Application')
end

And(/^application verification is OUTSTANDING$/) do
	person = Person.all.first
  expect(person.consumer_role.application_validation).to eq('outstanding')
  expect(page).to have_content('Outstanding')
end

And(/^Identity verification is OUTSTANDING$/) do
	person = Person.all.first
	expect(person.consumer_role.identity_validation).to eq('outstanding')
	expect(page).to have_content('Outstanding')
end

Then(/^the CONTINUE button is functionally DISABLED$/) do
	find('.interaction-click-control-continue')['disabled'].should == "disabled"
end

Then(/^visibly DISABLED$/) do
	find('.interaction-click-control-continue')['disabled'].should == "disabled"
end

And(/^an uploaded application in REVIEW status is present$/) do
  find('#upload_application').click
	within '#upload_application' do
		attach_file("file[]", "#{Rails.root}/lib/pdf_templates/blank.pdf", visible:false)
  end
  wait_for_ajax(2)
	expect(page).to have_content('File Saved')
	expect(page).to have_content('In Review')
	person = Person.all.first
	expect(person.consumer_role.application_validation).to eq('pending')
end

And(/^an uploaded identity verification in REVIEW status is present$/) do
	find('#upload_identity').click
	find('#select_upload_identity').click
	within '#select_upload_identity' do
		attach_file("file[]", "#{Rails.root}/lib/pdf_templates/blank.pdf", visible:false)

  end
  wait_for_ajax(2)
	expect(page).to have_content('File Saved')
	expect(page).to have_content('In Review')
	person = Person.all.first
	expect(person.consumer_role.identity_validation).to eq('pending')
end

And(/^an uploaded application in VERIFIED status is present$/) do
	login_as hbx_admin, scope: :user
	visit exchanges_hbx_profiles_root_path
	click_link 'Families'
  wait_for_ajax(10,2)
	family_member = find('a', :text => /First/)
	family_member.click
	expect(page).to have_content('Application')
  find(:xpath, "/html/body/div[2]/div[2]/div/div/div[1]/div[2]/div/div/div/div[2]/div[5]/div/div[4]/div").click
  find('.interaction-choice-control-verification-reason-1').click
  find('.interaction-choice-control-verification-reason', :text => /\ASelect Reason\z/).click
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click
  expect(page).to have_content('Application successfully verified.')
end

And(/^an uploaded Identity verification in VERIFIED status is present$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  click_link 'Families'
  wait_for_ajax(10,2)
  family_member = find('a', :text => /First/)
  family_member.click
  expect(page).to have_content('Identity')
  find(:xpath, "/html/body/div[2]/div[2]/div/div/div[1]/div[2]/div/div/div/div[2]/div[1]/div/div[4]/div").click
  find('.interaction-choice-control-verification-reason-1').click
  find('.interaction-choice-control-verification-reason', :text => /\ASelect Reason\z/).click
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click
  expect(page).to have_content('Identity successfully verified.')
end

Then(/^the CONTINUE button is functionally ENABLED$/) do
  find('.interaction-click-control-continue').visible?
end

Then(/^visibly ENABLED$/) do
  find('.interaction-click-control-continue').visible?
end

When(/^the Admin clicks “Continue” on the doc upload page$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  click_link 'Families'
  wait_for_ajax(10,2)
  family_member = find('a', :text => /First/)
  family_member.click
end

Then(/^the Admin is able to complete the application for the consumer$/) do
  find('.interaction-click-control-continue').click
  expect(page).to have_content('Add Member')
  screenshot("dependents")
end


When(/^the consumer selects “I Agree”$/) do
  expect(page).to have_content('Authorization and Consent')
  find(:xpath, '//label[@for="agreement_agree"]').click
  click_link "Continue"
end

Then(/^the consumer will be directed to answer the Experian Identity Proofing questions$/) do
  expect(page).to have_content('Verify Identity')
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]').click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]').click
end

And(/^that the consumer has answered the Experian Identity Proofing questions$/) do
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_0_response_id_a"]').click
  find(:xpath, '//label[@for="interactive_verification_questions_attributes_1_response_id_c"]').click
  screenshot("identify_verification")
  click_button "Submit"
end

When(/^Experian is unable to verify Identity for the consumer$/) do
  expect(page).to have_content('Identity')
  expect(page).to have_content('Application')
end

When(/^an Experian Error screen appears for the consumer$/) do
  expect(page).to have_content('Your identity could not be confirmed by Experian')
end

When(/^an uploaded Identity verification in VERIFIED status is present on failed experian screen$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  click_link 'Families'
  wait_for_ajax(10,2)
  family_member = find('a', :text => /First/)
  family_member.click
  expect(page).to have_content('Identity')
  find(:xpath, "/html/body/div[2]/div[2]/div/div/div[1]/div[3]/div[1]/div/div/div/div[2]/div[1]/div/div[4]/div").click
  find('.interaction-choice-control-verification-reason-1').click
  find('.interaction-choice-control-verification-reason', :text => /\ASelect Reason\z/).click
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click
  expect(page).to have_content('Identity successfully verified.')
end

When(/^an uploaded application in VERIFIED status is present on failed experian screen$/) do
  login_as hbx_admin, scope: :user
  visit exchanges_hbx_profiles_root_path
  click_link 'Families'
  wait_for_ajax(10,2)
  family_member = find('a', :text => /First/)
  family_member.click
  expect(page).to have_content('Application')
  find(:xpath, "/html/body/div[2]/div[2]/div/div/div[1]/div[3]/div[1]/div/div/div/div[2]/div[5]/div/div[4]/div").click
  find('.interaction-choice-control-verification-reason-1').click
  find('.interaction-choice-control-verification-reason', :text => /\ASelect Reason\z/).click
  select('Document in EnrollApp', :from => 'verification_reason')
  find('.v-type-confirm-button').click
  expect(page).to have_content('Application successfully verified.')
end
