require 'watir'
require 'pry'
# load Rails.root + "db/seeds.rb"
module WatirScreenshots
  def screenshot(name = nil)
    if @take_screens
      shot_count = @screen_count.to_s.rjust(3, "0")
      f_name = name.nil? ? shot_count : "#{shot_count}_#{name}"
      @browser.screenshot.save("tmp/#{f_name}.png")
      @screen_count = @screen_count + 1
    end
  end
end

When(/I use unique values/) do
  require 'test/unique_value_stash.rb'
  include UniqueValueStash
  @u = UniqueValueStash::UniqueValues.new unless defined?(@u)
end

def people
  return @a if defined?(@a)
  @a = {
    "Soren White" => {
      first_name: "Soren",
      last_name: "White",
      dob: "08/13/1979",
      ssn: "670991234",
      home_phone: "2025551234",
      email: 'soren@dc.gov',
      password: 'aA1!aA1!aA1!',
      legal_name: "Acme Inc.",
      dba: "Acme Inc.",
      fein: "764141112"
    },
    "Patrick Doe" => {
      first_name: "Patrick",
      last_name: "Doe",
      dob: "01/01/1980",
      ssn: "786120965",
      email: 'patrick.doe@dc.gov',
      password: 'aA1!aA1!aA1!'
    },
    "Broker Assisted" => {
      first_name: 'Broker',
      last_name: 'Assisted',
      dob: "05/02/1976",
      ssn: "761234567",
      email: 'broker.assisted@dc.gov',
      password: 'aA1!aA1!aA1!'
    },
    "Fred" => {
      first_name: 'Fred',
      last_name: 'Thirteen',
      dob: defined?(@u) ? @u.adult_dob : "08/13/1979",
      ssn: defined?(@u) ? @u.ssn : "761234567",
      email: defined?(@u) ? @u.email : 'fred@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "Megan" => {
      first_name: 'Megan',
      last_name: 'Smith',
      dob: defined?(@u) ? @u.adult_dob : "08/13/1979",
      ssn: defined?(@u) ? @u.ssn : "761234567",
      email: defined?(@u) ? @u.email : 'megan@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "Hbx Admin" => {
      email: 'admin@dc.gov',
      password: 'aA1!aA1!aA1!'
    },
    "Primary Broker" => {
      email: 'ricky.martin@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "John Doe" => {
      first_name: "John",
      last_name: "Doe#{rand(1000)}",
      dob: @u.adult_dob,
      legal_name: "Turner Agency, Inc",
      dba: "Turner Agency, Inc",
      fein: @u.fein,
      ssn: @u.ssn,
      email: @u.email,
      password: 'aA1!aA1!aA1!'

    },
    "Tim Wood" => {
      first_name: "Tim",
      last_name: "Wood",
      dob: "08/13/1979",
      legal_name: "Legal LLC",
      dba: "Legal LLC",
      fein: "890000223",
      email: 'tim.wood@example.com',
      password: 'aA1!aA1!aA1!'
    },
    "Tronics" => {
      first_name: "Tronics",
      last_name: "Rocks#{rand(1000)}",
      dob: defined?(@u) ?  @u.adult_dob : "08/13/1979",
      legal_name: "Tronics",
      dba: "Tronics",
      fein: defined?(@u) ? @u.fein : '123123123',
      email: defined?(@u) ? @u.email : 'tronics@example.com',
      password: 'aA1!aA1!aA1!'
    },
  }
end

def scroll_into_view(element)
  @browser.execute_script(
    'arguments[0].scrollIntoView(false);',
    element
  )
  element
end

def scroll_then_click(element)
  scroll_into_view(element).click
  element
end

def click_when_present(element)
  element.wait_until_present
  scroll_then_click(element)
end

def wait_and_confirm_text(text)
  @browser.element(text: text).wait_until_present
  expect(@browser.element(text:text).visible?).to be_truthy
end

def fill_user_registration_form(credentials)
  @browser.text_field(name: "user[password_confirmation]").wait_until_present
  @browser.text_field(name: "user[email]").set(credentials[:email])
  @browser.text_field(name: "user[password]").set(credentials[:password])
  @browser.text_field(name: "user[password_confirmation]").set(credentials[:password])
end

def default_office_location
  {
  address1: "623a Spalding Ct",
  address2: "Suite 200",
  city: "Washington",
  state: "DC",
  zip: "20001",
  phone_area_code: "202",
  phone_number: "1110000",
  phone_extension: "1111"
  }
end

When(/^.+ enters? office location for (.+)$/) do |location|
  location = eval(location) if location.class == String
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_1]', :with => location[:address1]
  fill_in 'organization[office_locations_attributes][0][address_attributes][address_2]', :with => location[:address2]
  fill_in 'organization[office_locations_attributes][0][address_attributes][city]', :with => location[:city]

  find(:xpath, "//div[@class='selectric'][p[contains(text(), 'SELECT STATE')]]").click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), '#{location[:state]}')]").click

  fill_in 'organization[office_locations_attributes][0][address_attributes][zip]', :with => location[:zip]
  fill_in 'organization[office_locations_attributes][0][phone_attributes][area_code]', :with => location[:phone_area_code]
  fill_in 'organization[office_locations_attributes][0][phone_attributes][number]', :with => location[:phone_number]
  fill_in 'organization[office_locations_attributes][0][phone_attributes][extension]', :with => location[:phone_extension]
end

When(/^(.+) creates? a new employer profile$/) do |named_person|
  employer = people[named_person]
  fill_in 'organization[first_name]', :with => employer[:first_name]
  fill_in 'organization[last_name]', :with => employer[:last_name]
  fill_in 'jq_datepicker_ignore_organization[dob]', :with => employer[:dob]

  find('#organization_legal_name').click
  fill_in 'organization[legal_name]', :with => employer[:legal_name]
  fill_in 'organization[dba]', :with => employer[:dba]
  fill_in 'organization[fein]', :with => employer[:fein]

  find('.selectric-interaction-choice-control-organization-entity-kind').click
  find(:xpath, "//div[@class='selectric-scroll']/ul/li[contains(text(), 'C Corporation')]").click
  step "I enter office location for #{default_office_location}"
  find('.interaction-click-control-confirm').click
end

When(/^(.*) logs on to the (.*)?/) do |named_person, portal|
  person = people[named_person]
  @browser.goto("http://localhost:3000/")
  portal_class = "interaction-click-control-#{portal.downcase.gsub(/ /, '-')}"
  @browser.a(class: portal_class).wait_until_present
  @browser.a(class: portal_class).click
  @browser.element(class: /interaction-click-control-sign-in-existing-account/).wait_until_present
  @browser.element(class: /interaction-click-control-sign-in-existing-account/).click
  sleep 2
  @browser.text_field(class: /interaction-field-control-user-email/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(person[:email])
  @browser.text_field(class: /interaction-field-control-user-password/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-password/).set(person[:password])
  @browser.element(class: /interaction-click-control-sign-in/).click
end

Then(/^.+ creates (.+) as a roster employee$/) do |named_person|
  person = people[named_person]
  @browser.text_field(class: /interaction-field-control-census-employee-first-name/).wait_until_present
  @browser.element(class: /interaction-click-control-create-employee/).wait_until_present
  screenshot("create_census_employee")
  @browser.text_field(class: /interaction-field-control-census-employee-first-name/).set(person[:first_name])
  @browser.text_field(class: /interaction-field-control-census-employee-last-name/).set(person[:last_name])
  @browser.text_field(name: "jq_datepicker_ignore_census_employee[dob]").set(person[:dob])
  #@browser.text_field(class: /interaction-field-control-census-employee-dob/).set("01/01/1980")
  @browser.text_field(class: /interaction-field-control-census-employee-ssn/).set(person[:ssn])
  #@browser.radio(class: /interaction-choice-control-value-radio-male/).set
  @browser.radio(id: /radio_male/).fire_event("onclick")
  @browser.text_field(name: "jq_datepicker_ignore_census_employee[hired_on]").set((Time.now-1.week).strftime('%m/%d/%Y'))
  #@browser.text_field(class: /interaction-field-control-census-employee-hired-on/).set("10/10/2014")
  @browser.checkbox(class: /interaction-choice-control-value-census-employee-is-business-owner/).set
  input_field = @browser.divs(class: /selectric-wrapper/).first
  input_field.click
  click_when_present(input_field.lis()[1])
  # Address
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-address-1/).wait_until_present
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-address-1/).set("1026 Potomac")
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-address-2/).set("apt abc")
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-city/).set("Alpharetta")
  select_state = @browser.divs(text: /SELECT STATE/).last
  select_state.click
  scroll_then_click(@browser.li(text: /GA/))
  @browser.text_field(class: /interaction-field-control-census-employee-address-attributes-zip/).set("30228")
  email_kind = @browser.divs(text: /SELECT KIND/).last
  email_kind.click
  @browser.li(text: /home/).click
  @browser.text_field(class: /interaction-field-control-census-employee-email-attributes-address/).set("broker.assist@dc.gov")
  screenshot("broker_create_census_employee_with_data")
  @browser.element(class: /interaction-click-control-create-employee/).click
end

Given(/^(.+) has not signed up as an HBX user$/) do |actor|
  step "I use unique values"
end

When(/^I visit the Employer portal$/) do
  visit "/"
  page.click_link 'Employer Portal'
end

Then(/^(?:.+) should see a successful sign up message$/) do
  expect(page).to have_content('Welcome to DC Health Link. Your account has been created.')
end

Then(/^(?:.+) should click on employer portal$/) do
  visit "/"
  page.click_link 'Employer Portal'
end

When(/^(?:.+) go(?:es)? to the employee account creation page$/) do
  visit "/"
  click_link 'Employee Portal'
end

Then(/^(?:.+) should be logged on as an unlinked employee$/) do
    screenshot("logged_in_welcome")
  @browser.a(href: /consumer\/employee\/search/).wait_until_present
  screenshot("logged_in_welcome")
  expect(@browser.a(href: /consumer.employee.search/).visible?).to be_truthy
end

When (/^(.*) logs? out$/) do |someone|
  find('.interaction-click-control-logout').click
end

When(/^.+ go(?:es)? to register as an employee$/) do
  find('.interaction-click-control-continue').click
end

Then(/^.+ should see the employee search page$/) do
  expect(find('.interaction-field-control-person-first-name')).to be_visible
end

When(/^(.*) creates an HBX account$/) do |named_person|
  click_button 'Create account'

  person = people[named_person]

  fill_in "user[email]", :with => person[:email]
  fill_in "user[password_confirmation]", :with => person[:password]
  fill_in "user[password]", :with => person[:password]
  click_button "Create account"
end

When(/^.+ enters? the identifying info of (.*)$/) do |named_person|
  person = people[named_person]

  fill_in 'person[first_name]', :with => person[:first_name]
  fill_in 'person[last_name]', :with => person[:last_name]
  fill_in 'jq_datepicker_ignore_person[dob]', :with => person[:dob]
  fill_in 'person[ssn]', :with => person[:ssn]
  find(:xpath, '//label[@for="radio_male"]').click

  find('.interaction-click-control-continue').click
end

Then(/^.+ should not see the matched employee record form$/) do
  @browser.element(class: /fa-exclamation-triangle/).wait_until_present
  expect(@browser.element(class: /interaction-click-control-this-is-my-employer/).exists?).to be_falsey
end

Then(/^Employee should see the matched employee record form$/) do
  @browser.p(text: /Acme Inc\./).wait_until_present
  screenshot("employer_search_results")
  expect(@browser.p(text: /Acme Inc\./).visible?).to be_truthy
end

# TODO: needs to be merged
Then(/^.+ should see the matching employee record form$/) do
  expect(page).to have_content('Turner Agency')
end

When(/^.+ accepts? the matched employer$/) do
  click_button 'This is my employer'
end

When(/^.+ completes? the matched employee form for (.*)$/) do |named_person|
  person = people[named_person]
  find('.interaction-click-control-click-here').click
  find('.interaction-click-control-close').click

  find("#person_addresses_attributes_0_address_1").click
  find("#person_addresses_attributes_0_address_2").click
  find("#person_addresses_attributes_0_city").click
  find("#person_addresses_attributes_0_zip").click

  fill_in "person[phones_attributes][0][full_phone_number]", :with => person[:home_phone]

  find("#btn-continue").click
end

Then(/^.+ should see the dependents page$/) do
  expect(page).to have_content('Add Member')
end

When(/^.+ clicks? edit on baby Soren$/) do
  scroll_then_click(@browser.span(text: "07/03/2014").as(xpath: "./preceding::a[contains(@href, 'edit')]").last)
end

Then(/^.+ should see the edit dependent form$/) do
  @browser.button(:text => /Confirm Member/i).wait_until_present
end

When(/^.+ clicks? delete on baby Soren$/) do
  scroll_then_click(@browser.form(id: 'edit_dependent').a())
  @browser.div(id: 'remove_confirm').wait_until_present
  scroll_then_click(@browser.a(class: /confirm/))
  @browser.button(text: /Confirm Member/i).wait_while_present
end

Then(/^.+ should see (.*) dependents*$/) do |n|
  expect(page).to have_selector('li.dependent_list', :count => n.to_i)
end

When(/^.+ clicks? Add Member$/) do
  scroll_then_click(@browser.a(text: /Add Member/))
  @browser.button(text: /Confirm Member/i).wait_until_present
end

Then(/^.+ should see the new dependent form$/) do
  expect(@browser.button(text: /Confirm Member/i).visible?).to be_truthy
end

When(/^.+ enters? the dependent info of Sorens daughter$/) do
  @browser.text_field(name: 'dependent[first_name]').set('Cynthia')
  @browser.text_field(name: 'dependent[last_name]').set('White')
  @browser.text_field(name: 'jq_datepicker_ignore_dependent[dob]').set('01/15/2011')
  input_field = @browser.div(class: /selectric-wrapper/)
  input_field.click
  input_field.li(text: /Child/).click
  @browser.text_field(name: 'dependent[addresses][0][address_1]').set('623a Spalding Ct')
  @browser.text_field(name: 'dependent[addresses][0][city]').set('Washington')
  input_field = @browser.select(name: /state/).divs(xpath: "ancestor::div")[-2]
  input_field.click
  input_field.li(text: /DC/).click
  @browser.text_field(name: 'dependent[addresses][0][zip]').set('20001')
  @browser.radio(id: /radio_female/).fire_event("onclick")
end

When(/^.+ clicks? confirm member$/) do
  scroll_then_click(@browser.button(text: /Confirm Member/i))
  @browser.button(text: /Confirm Member/i).wait_while_present
end

When(/^.+ clicks? continue on the dependents page$/) do
  find('#btn-continue').click
end

Then(/^.+ should see the group selection page$/) do
  expect(page).to have_css('form')
end

When(/^.+ clicks? continue on the group selection page$/) do
  find('#btn-continue').click
end

Then(/^.+ should see the plan shopping welcome page$/) do
  expect(page).to have_content('Choose Plan')
end

When(/^.+ clicks? continue on the plan shopping welcome page$/) do
  scroll_then_click(@browser.a(text: "Continue"))
end


Then(/^.+ should see the list of plans$/) do
  expect(page).to have_link('Select')
end

When(/^.+ selects? a plan on the plan shopping page$/) do
  click_link 'Select Plan'
end

Then(/^.+ should see the coverage summary page$/) do
  expect(page).to have_content('Confirm Your Plan Selection')
end

When(/^.+ clicks? on Confirm button on the coverage summary page$/) do
  find('.interaction-click-control-confirm').click
end

Then(/^.+ should see the receipt page$/) do
  expect(page).to have_content('Enrollment Submitted')
  find('.interaction-click-control-continue').click
end

Then(/^.+ should see the "my account" page$/) do
  expect(page).to have_content('My DC Health Link')
end

Then(/^.+ should see the "Your Enrollment History" section/) do
  @browser.element(text: /YOUR ENROLLMENT HISTORY/i).wait_until_present
  expect(@browser.element(text: /YOUR ENROLLMENT HISTORY/i).visible?).to be_truthy
end

When(/^.+ clicks? a qle event$/) do
  scroll_then_click(@browser.a(text: /Divorce/))
  @browser.text_field(class: "interaction-field-control-qle-date").set((Date.today + 5).strftime("%m/%d/%Y"))
  scroll_then_click(@browser.a(class: /interaction-click-control-submit/))
  @browser.element(text: /You may be eligible for a special enrollment period./i).wait_until_present
  expect(@browser.element(text: /You may be eligible for a special enrollment period./i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/))
  @browser.element(text: /Household Info: Family Members/i).wait_until_present
  expect(@browser.element(text: /Household Info: Family Members/i).visible?).to be_truthy
  scroll_then_click(@browser.a(id: /btn_household_continue/))
  @browser.element(text: /Choose Benefits: Covered Family Members/i).wait_until_present
  expect(@browser.element(text: /Choose Benefits: Covered Family Members/i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-keep-existing-plan/))
end

Then(/^.+ can purchase a plan$/) do
  @browser.element(text: /Confirm Your Plan Selection/i).wait_until_present
  expect(@browser.element(text: /Confirm Your Plan Selection/i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-purchase/))
  @browser.element(text: /Purchase confirmation/i).wait_until_present
  expect(@browser.element(text: /Purchase confirmation/i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/))
  @browser.element(text: /Your PLAN/i).wait_until_present
  expect(@browser.element(text: /YOUR PLAN/i).visible?).to be_truthy
end

When(/^Employer publishes a plan year$/) do
  click_when_present(@browser.element(class: /interaction-click-control-benefits/))
  click_when_present(@browser.element(class: /interaction-click-control-edit-plan-year/))
  @browser.element(class: /interaction-choice-control-plan-year-start-on/).wait_until_present
  @browser.element(class: /interaction-choice-control-plan-year-start-on/).click
  # start_on = @browser.p(text: /SELECT START ON/i)
  # click_when_present(start_on)
  start_on = @browser.li(text: /SELECT START ON/i)
  click_when_present(start_on.parent().lis()[1])
  click_when_present(@browser.element(class: /change-plan/))
  select_plan_option = @browser.ul(class: /nav-tabs/)
  select_plan_option.li(text: /By carrier/i).click
  carriers_tab = @browser.div(class: /carriers-tab/)
  @browser.element(text: /edit your plan offering/i).wait_until_present
  carriers_tab.as[1].fire_event("onclick")
  plans_tab = @browser.div(class: /reference-plans/)
  @browser.element(text: /select your reference plan/i).wait_until_present
  plans_tab.labels.last.fire_event('onclick')
  click_when_present(@browser.button(class: /interaction-click-control-save-plan-year/))
  @browser.element(class: /alert-notice/, text: /Plan Year successfully saved./).wait_until_present
  click_when_present(@browser.element(class: /interaction-click-control-benefits/))
  click_when_present(@browser.element(class: /interaction-click-control-publish-plan-year/))
end

When(/^.+ should see a published success message$/) do
  expect(find('.alert')).to have_content('Plan Year successfully published')
end

When(/^.+ goes to to home tab$/) do
  @browser.element(class: /interaction-click-control-my-dc-health-link/).fire_event('onclick')
end

Then(/^.+ should see the current plan year$/) do
  @browser.element(text: /My Health Benefits Program/i).wait_until_present
  # expect(@browser.h5(text: /Plan Year/i).visible?).to be_truthy
end

And(/^.+ should see the premium billings report$/) do
  # expect(@browser.h3(text: /Premium Billing Report/i).visible?).to be_truthy
end

When(/^.+ should see a published success message without employee$/) do
  @browser.element(text: /You have 0 non-owner employees on your roster/).wait_until_present
  expect(@browser.element(text: /You have 0 non-owner employees on your roster/).visible?).to be_truthy
end

When(/^.+ clicks? on the add employee button$/) do
  find('.interaction-click-control-add-new-employee').click
end

When(/^.+ clicks? on the (.+) tab$/) do |tab_name|
  find(:xpath, "//nav[@class='row']/ul/li[contains(., '#{tab_name}')]").click
end

When(/^.+ clicks? on the tab for (.+)$/) do |tab_name|
  @browser.element(class: /interaction-click-control-#{tab_name}/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-#{tab_name}/))
end

When(/^I click the "(.*?)" in qle carousel$/) do |qle_event|
  sleep 3
  click_when_present(@browser.a(text: /#{qle_event}/))
end

When(/^I click on "(.*?)" button on household info page$/) do |select_action|
  @browser.element(text: /Choose Coverage for your Household/i).wait_until_present
  expect(@browser.element(text: /Choose Coverage for your Household/i).visible?).to be_truthy
  scroll_then_click(@browser.button(class: /interaction-click-control-shop-for-new-plan/))
end

When(/^I click on continue on qle confirmation page$/) do
  @browser.element(text: /Enrollment Submitted/i).wait_until_present
  expect(@browser.element(text: /Enrollment Submitted/i).visible?).to be_truthy
  screenshot("qle_confirm")
  click_when_present(@browser.a(text: /go to my account/i))
end


When(/^I select a future qle date$/) do
  @browser.text_field(class: "interaction-field-control-qle-date").set((Date.today + 5).strftime("%m/%d/%Y"))
  sleep(1)
  screenshot("future_qle_date")
  scroll_then_click(@browser.a(class: /interaction-click-control-continue/))
end

Then(/^I should see not qualify message$/) do
  wait_and_confirm_text /The date you submitted does not qualify for special enrollment/i
  expect(@browser.element(text: /The date you submitted does not qualify for special enrollment/i).visible?).to be_truthy
  screenshot("not_qualify")
end

When(/^I select a past qle date$/) do
  @browser.text_field(class: "interaction-field-control-qle-date").set((Date.today - 5).strftime("%m/%d/%Y"))
  sleep(1)
  screenshot("past_qle_date")
  scroll_then_click(@browser.a(class: /interaction-click-control-continue/))
end

Then(/^I should see confirmation and continue$/) do
  expect(@browser.element(text: /Based on the information you entered, you may be eligible/i).visible?).to be_truthy
  screenshot("valid_qle")
  scroll_then_click(@browser.button(class: /interaction-click-control-continue/))
end

Then(/^I should see the dependents and group selection page$/) do
  #@browser.element(text: /Household Info: Family Members/i).wait_until_present
  expect(@browser.element(text: /Household Info: Family Members/i).visible?).to be_truthy
  @browser.element(class: /interaction-click-control-continue/).wait_until_present
  @browser.execute_script("$('.interaction-click-control-continue')[1].click();")
  @browser.element(text: /Choose Benefits: Covered Family Members/i).wait_until_present
  expect(@browser.element(text: /Choose Benefits: Covered Family Members/i).visible?).to be_truthy
  scroll_then_click(@browser.button(class: /interaction-click-control-shop-for-new-plan/))
  @browser.element(text: /Choose Plan/i).wait_until_present
  expect(@browser.element(text: /Choose Plan/i).visible?).to be_truthy
  @browser.execute_script("$('.interaction-click-control-select-plan')[1].click()")
  @browser.element(text: /Confirm Your Plan Selection/i).wait_until_present
  expect(@browser.element(text: /Confirm Your Plan Selection/i).visible?).to be_truthy
  scroll_then_click(@browser.a(class: /interaction-click-control-purchase/))
end

And(/I select three plans to compare/) do
  # sleep 3
  @browser.a(text: /Select Plan/).wait_until_present
  compare_options = @browser.spans(class: 'checkbox-custom-label', text: "Compare")
  if compare_options.count > 3
    compare_options[0].click
    compare_options[1].click
    compare_options[2].click
    click_when_present(@browser.a(text: "COMPARE PLANS"))
    @browser.h1(text: /Choose Plan - Compare Selected Plans/).wait_until_present
    expect(@browser.elements(:class => "plan_comparison").size).to eq 3
    @browser.button(text: 'Close').wait_until_present
    @browser.button(text: 'Close').click
  end
end

And(/I should not see any plan which premium is 0/) do
  @browser.h2s(class: "plan-premium")[1].wait_until_present
  expect(@browser.h2s(class: "plan-premium", text: "$0.00").count).to eq 0
end
