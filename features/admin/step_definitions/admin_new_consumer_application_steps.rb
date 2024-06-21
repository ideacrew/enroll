Given(/^Hbx Admin is on ridp document upload page$/) do
  visit '/insured/consumer_role/upload_ridp_document'
end

When(/^hbx admin uploads application document and verifies application$/) do
  doc_id  = "urn:openhbx:terms:v1:file_storage:s3:bucket:'id-verification'{#sample-key}"
  file_path = File.dirname(__FILE__)
  allow_any_instance_of(Insured::RidpDocumentsController).to receive(:file_path).and_return(file_path)
  allow(Aws::S3Storage).to receive(:save).with(file_path, 'id-verification').and_return(doc_id)
  find('#upload_application').click
  within '#upload_application' do
    attach_file("file[]", "#{Rails.root}/lib/pdf_templates/blank.pdf", visible:false)
  end
  wait_for_ajax(2)
  expect(page).to have_content('File Saved')
  expect(page).to have_content('In Review')
  within('#Application') do
    find('.label', :text => 'Action').click
    find('li', :text => 'Verify').click
  end

  find('.verification-update-reason').click
  find('li', :text => 'Document in EnrollApp').click
  find('.v-type-confirm-button').click

  expect(page).to have_content('Application successfully verified.')
end

Then(/^Hbx admin visits household info page$/) do
  expect(page).to have_content('Family Information')
end

Then(/^Admin continues to families home page$/) do
  visit 'families/home'
end

When(/^user registers as an individual$/) do
  fill_in IvlPersonalInformation.first_name, with: "John"
  fill_in IvlPersonalInformation.last_name, with: "Smith"
  fill_in IvlPersonalInformation.dob, with: "11/11/1991"
  fill_in IvlPersonalInformation.ssn, with: '212-31-3131'
  find(IvlPersonalInformation.male_radiobtn).click
  find(IvlPersonalInformation.need_coverage_yes).click
  find(IvlPersonalInformation.continue_btn).click
end

When(/^user registers as an individual female gender$/) do
  fill_in IvlPersonalInformation.first_name, with: "John"
  fill_in IvlPersonalInformation.last_name, with: "Smith"
  fill_in IvlPersonalInformation.dob, with: "11/11/1991"
  fill_in IvlPersonalInformation.ssn, with: '212-31-3131'
  find(IvlPersonalInformation.female_radiobtn).click
  find(IvlPersonalInformation.need_coverage_yes).click
  find(IvlPersonalInformation.continue_btn).click
end

When(/^the Individual selects “I Disagree”$/) do
  find(:xpath, '//label[@for="agreement_disagree"]').click
end

When(/^the Individual clicks CONTINUE$/) do
  click_link "Continue"
end

Then(/^Individual should land on Documents upload page$/) do
  expect(page).to have_content('Verified')
  expect(page).to have_content('Identity')
  expect(page).to have_content('Application')
end

When(/^clicks on Individual in Families tab$/) do
  login_as hbx_admin
  visit exchanges_hbx_profiles_root_path
  find(:xpath, "//li[contains(., '#{"Families"}')]", :wait => 10).click
  find('li', :text => 'Families', :class => 'tab-second', :wait => 10).click
  find('a', :text => /\AJohn Smith\z/, :wait => 10).click
  expect(page).to have_content('Identity')
end

Then(/^Admin should land on ridp document upload page$/) do
  expect(page).to have_content('Identity')
end

