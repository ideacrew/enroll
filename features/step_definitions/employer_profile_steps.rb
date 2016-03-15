Given /(\w+) is a person/ do |name|
  @a = Time.now unless @a
  person = FactoryGirl.create(:person, first_name: name)
  @pswd = 'aA1!aA1!aA1!'
  user = User.create(email: Forgery('email').address, password: @pswd, password_confirmation: @pswd, person: person)
end

Then  /(\w+) signs in/ do |name|
  person = Person.where(first_name: name).first
  @browser.element(class: /interaction-click-control-sign-in-existing-account/).wait_until_present
  @browser.element(class: /interaction-click-control-sign-in-existing-account/).click
  @browser.text_field(class: /interaction-field-control-user-email/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(person.user.email)
  @browser.text_field(class: /interaction-field-control-user-password/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-password/).set('aA1!aA1!aA1!')
  @browser.element(class: /interaction-click-control-sign-in/).click
  @browser.element(class: /interaction-click-control-sign-in/).wait_while_present
end

Given /(\w+) is a user with no person who goes to the Employer Portal/ do |name|
  email = Forgery('email').address
  @browser.goto("http://localhost:3000/")
  portal_class = 'interaction-click-control-employer-portal'
  @browser.a(class: portal_class).wait_until_present
  @browser.a(class: portal_class).click
  @pswd = 'aA1!aA1!aA1!'
  @browser.text_field(class: /interaction-field-control-user-email/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(email)
  @browser.text_field(class: /interaction-field-control-user-password/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-password/).set(@pswd)
  @browser.text_field(class: /interaction-field-control-user-password-confirmation/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-password-confirmation/).set(@pswd)
  @browser.element(class: /interaction-click-control-create-account/).click
  @browser.element(class: /interaction-click-control-create-account/).wait_while_present
end

Given /(\w+) enters first, last, dob and contact info/ do |name|
  @browser.text_field(class: 'interaction-field-control-person-first-name').set(name)
  @browser.text_field(class: 'interaction-field-control-person-last-name').set(Forgery('name').last_name)
  @browser.text_field(class: 'interaction-field-control-person-dob').set('03/03/1993')
  @browser.text_field(class: 'interaction-field-control-person-first-name').click
  @browser.text_field(class: 'interaction-field-control-person-email').set(Forgery('internet').email_address)
  @browser.text_field(class: 'interaction-field-control-person-area-code').set(202)
  @browser.text_field(class: 'interaction-field-control-person-number').set('555-1212')
end

Then(/(\w+) is the staff person for an employer/) do |name|
  person = Person.where(first_name: name).first
  employer_profile = FactoryGirl.create(:employer_profile)
  employer_staff_role = FactoryGirl.create(:employer_staff_role, person: person, employer_profile_id: employer_profile.id)
end

When(/(\w+) accesses the Employer Portal/) do |name|
  person = Person.where(first_name: name).first
  @browser.goto("http://localhost:3000/")
  portal_class = 'interaction-click-control-employer-portal'
  @browser.a(class: portal_class).wait_until_present
  @browser.a(class: portal_class).click
  step "#{name} signs in"
  end

Then /(\w+) decides to Update Business information/ do |person|
  @browser.a(class: /interaction-click-control-update-business-info/).wait_until_present
  @browser.a(class: /interaction-click-control-update-business-info/).click
  sleep 1
  screenshot('update_business_info')
end

Given /(\w+) adds an EmployerStaffRole to (\w+)/ do |staff, new_staff|
  person = Person.where(first_name: new_staff).first
  button_class = 'interaction-click-control-add-employer-staff-role'
  @browser.element(class: button_class).wait_until_present
  @browser.element(class: button_class).click
  first_field = 'interaction-field-control-first-name'
  last_field = 'interaction-field-control-last-name'
  dob_field = 'interaction-field-control-dob'
  expect(@browser.trs.count).to eq(2)
  @browser.element(class: first_field).wait_until_present
  @browser.text_field(class: first_field).set(person.first_name)
  @browser.text_field(class: last_field).set(person.last_name)
  @browser.text_field(class: dob_field).set(person.dob)
  screenshot('add_existing_person_as_staff')
  @browser.button(class: 'interaction-click-control-save').click
end

Then /Point of Contact count is (\d+)/ do |count|
  @browser.tbody.wait_until_present
  rows = @browser.tbody.trs.count
  expect(rows).to eq(count.to_i)
end

Then /Hannah cannot remove EmployerStaffRole from Hannah/ do
  staff = Person.where(first_name: 'Hannah').first
  @browser.execute_script("window.confirm = function() {return true}")
  @browser.link(id: 'delete_' + staff.id.to_s).click
  @browser.div(text: /before deleting this role/).wait_until_present
end
When /(\w+) removes EmployerStaffRole from (\w+)/ do |staff1, staff2|
  staff = Person.where(first_name: staff2).first
  @browser.execute_script("window.confirm = function() {return true}")
  @browser.link(id: 'delete_' + staff.id.to_s).click

end

When /(\w+) approves EmployerStaffRole for (\w+)/ do |staff1, staff2|
  staff = Person.where(first_name: staff2).first
  @browser.link(id: 'approve_' + staff.id.to_s).click
  screenshot('before_approval')
  @browser.div(class: 'alert-notice').wait_until_present
  expect(@browser.div(class: 'alert-notice').text).to match /Role is approved/
  screenshot('after_approval')
end

Then /(\w+) sees new employer page/ do |ex_staff|
  @browser.h2(text: /Thank you for logging into/).wait_until_present
  match = @browser.url.match  /employers\/employer_profiles\/new/        
  expect(match.present?).to be_truthy
end
Then /show elapsed time/  do
  puts Time.now - @a
end
Then /(\w+) selects Turner Agency, Inc from the dropdown/ do |name|
   @browser.text_field(class: 'typeahead').wait_until_present
   @browser.text_field(class: 'typeahead').set('Tu')
   @browser.span(class: 'twitter-typeahead').div(text: 'Turner Agency, Inc').wait_until_present
   screenshot('dropdown_for_existing_company')
   @browser.span(class: 'twitter-typeahead').div(text: 'Turner Agency, Inc').click
   sleep 1
   screenshot('display_data_for_existing_company')
   expect(@browser.input(id: 'employer_id').value).to be_truthy
end

Then /(\w+) is notified about Employer Staff Role (.*)/ do |name, alert|
   @browser.button(class: 'interaction-click-control-confirm').click
   sleep 1
   expect(@browser.div(class: 'alert-notice').text).to match /#{alert}/
   expect(@browser.h2(text: 'Thank you for logging into your DC')).to be_truthy
   screenshot('pending_person_stays_on_new_page')
 end

Given /Admin accesses the Employers tab of HBX portal/ do
  @browser.goto("http://localhost:3000/")
  portal_class = 'interaction-click-control-hbx-portal'
  @browser.a(class: portal_class).wait_until_present
  @browser.a(class: portal_class).click
  step "Admin signs in"
end
Given /Admin selects Hannahs company/ do
  tab_class = 'interaction-click-control-employers'
  @browser.link(class: tab_class).wait_until_present
  @browser.link(class: tab_class).click
  company = @browser.link(text: 'Turner Agency, Inc')
  company.wait_until_present
  company.click
end

Given /(\w+) has HBXAdmin privileges/ do |name|
  person = Person.where(first_name: name).first
  FactoryGirl.create(:hbx_staff_role, person: person)
end

Given(/^NewGuy enters the Primary Office Location info$/) do
  @browser.text_field(class: 'interaction-field-control-organization-legal-name').set(Forgery('name').company_name)
  @browser.text_field(class: 'interaction-field-control-organization-dba').set(Forgery('name').company_name)
  @fein = 100000000+rand(10000)
  @browser.text_field(class: 'interaction-field-control-organization-fein').set(@fein)
  sleep 1
  entity = @browser.divs(class: 'selectric')[0]
  entity.click
  @browser.li(text: /Partnership/i).click

  @browser.text_field(class: 'interaction-field-control-office-location-address-address-1').set('3 Jump St')
  @browser.text_field(class: 'interaction-field-control-office-location-address-city').set('Washington')
  entity = @browser.divs(class: 'selectric')[2]
  entity.click
  @browser.li(text: /DC/).click
  @browser.text_field(class: 'interaction-field-control-office-location-address-zip').set('20002')
  @browser.text_field(class: 'area_code').set('202')
  @browser.text_fields(placeholder: 'NUMBER').last.set('363-0145')
end

Given /The unclaimed company already exists/ do
  o=FactoryGirl.create(:organization, fein: @fein)
  ep= FactoryGirl.create(:employer_profile, organization: o)
end

Then /(\w+) becomes an Employer/ do |name|
  scroll_then_click(@browser.button(class: 'interaction-click-control-confirm'))
  @browser.div(text: /I'm an Employer/).wait_until_present
end

