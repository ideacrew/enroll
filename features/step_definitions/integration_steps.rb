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

Before "@watir" do
  extend WatirScreenshots
  @browser = Watir::Browser.new :chrome, switches: ["--test-type"]
  @browser.window.resize_to(1440, 900)
  @screen_count = 0
  @take_screens = ENV.has_key?("DISABLE_WATIR_SCREENSHOTS") ? false : true
  @keep_browser_open = ENV.has_key?("KEEP_WATIR_BROWSERS_OPEN") ? true : false
end

After "@watir" do
  @browser.close unless @keep_browser_open
  @take_screens = false if @take_screens
end

def people
  {
    "Soren White" => {
      first_name: "Soren",
      last_name: "White",
      dob: "08/13/1979",
      ssn: "670991234",
      home_phone: "2025551234", 
      email: 'soren@dc.gov',
      password: '12345678',
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
      password: '12345678'
    },
    "Broker Assisted" => {
      first_name: 'Broker',
      last_name: 'Assisted',
      dob: "05/02/1976",
      ssn: "761234567",
      email: 'broker.assisted@dc.gov',
      password: '12345678'
    },
    "Hbx Admin" => {
      email: 'admin@dc.gov',
      password: 'password'
    },
    "Primary Broker" => {
      email: 'ricky.martin@example.com',
      password: '12345678'
    },
    "John Doe" => {
      first_name: "John",
      last_name: "Doe",
      dob: "10/11/1985",
      legal_name: "Turner Agency, Inc",
      dba: "Turner Agency, Inc",
      fein: '123456999',
      ssn: '111000999',
      email: 'john.doe@example.com',
      password: '12345678'

    },
    "Tim Wood" => {
      first_name: "Tim",
      last_name: "Wood",
      dob: "08/13/1979",
      legal_name: "Legal LLC",
      dba: "Legal LLC",
      fein: "890000223",
      email: 'tim.wood@example.com',
      password: '12345678'
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
  @browser.text_field(class: /interaction-field-control-office-location-address-address-1/).set(location[:address1])
  @browser.text_field(class: /interaction-field-control-office-location-address-address-2/).set(location[:address2])
  @browser.text_field(class: /interaction-field-control-office-location-address-city/).set(location[:city])
  input_field = @browser.select(name: /state/).divs(xpath: "ancestor::div")[-2]
  input_field.click
  input_field.li(text: /#{location[:state]}/).click
  @browser.text_field(class: /interaction-field-control-office-location-address-zip/).set(location[:zip])
  @browser.text_field(class: /interaction-field-control-office-location-phone-area-code/).set(location[:phone_area_code])
  @browser.text_field(class: /interaction-field-control-office-location-phone-number/).set(location[:phone_number])
  @browser.text_field(class: /interaction-field-control-office-location-phone-extension/).set(location[:phone_extension])
end

When(/^(.+) creates? a new employer profile$/) do |named_person|
  employer = people[named_person]
  @browser.text_field(name: "organization[first_name]").wait_until_present
  @browser.text_field(name: "organization[first_name]").set(employer[:first_name])
  @browser.text_field(name: "organization[last_name]").set(employer[:last_name])
  @browser.text_field(name: "jq_datepicker_ignore_organization[dob]").set(employer[:dob])
  scroll_then_click(@browser.text_field(name: "organization[first_name]"))

  @browser.text_field(name: "organization[legal_name]").set(employer[:legal_name])
  @browser.text_field(name: "organization[dba]").set(employer[:dba])
  @browser.text_field(name: "organization[fein]").set(employer[:fein])
  input_field = @browser.divs(class: "selectric-interaction-choice-control-organization-entity-kind").first
  input_field.click
  input_field.li(text: /C Corporation/).click
  step "I enter office location for #{default_office_location}"
  scroll_then_click(@browser.button(class: "interaction-click-control-create-employer"))
end

When(/^(.*) logs on to the (.*)?/) do |named_person, portal|
  person = people[named_person]
  @browser.goto("http://localhost:3000/")
  portal_class = "interaction-click-control-#{portal.downcase.gsub(/ /, '-')}"
  @browser.a(class: portal_class).wait_until_present
  @browser.a(class: portal_class).click
  @browser.element(class: /interaction-click-control-sign-in/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(person[:email])
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
end

When(/^I visit the Employer portal$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: /Employer Portal/).wait_until_present
  @browser.a(text: /Employer Portal/).click
  screenshot("employer_start")
  @browser.a(text: /Create account/).wait_until_present
  @browser.a(text: /Create account/).click
end

Then(/^(?:.+) should see a successful sign up message$/) do
  Watir::Wait.until(30) { @browser.element(text: /Welcome! Your account has been created./).present? }
  screenshot("employer_sign_up_welcome")
  expect(@browser.element(text: /Welcome! Your account has been created./).visible?).to be_truthy
end

When(/^(?:.+) go(?:es)? to the employee account creation page$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: "Insured Portal").wait_until_present
  screenshot("start")
  scroll_then_click(@browser.a(text: "Insured Portal"))
  @browser.a(text: "Create account").wait_until_present
  screenshot("employee_portal")
  scroll_then_click(@browser.a(text: "Create account"))
end

Then(/^(?:.+) should be logged on as an unlinked employee$/) do
    screenshot("logged_in_welcome")
  @browser.a(href: /consumer\/employee\/search/).wait_until_present
  screenshot("logged_in_welcome")
  expect(@browser.a(href: /consumer.employee.search/).visible?).to be_truthy
end

When (/^(.*) logs? out$/) do |someone|
  sleep 2
  scroll_then_click(@browser.element(class: /interaction-click-control-logout/))
  @browser.element(class: /interaction-click-control-logout/).wait_while_present
  @browser.element(class: /interaction-click-control-insured-portal/).wait_until_present
end

When(/^.+ go(?:es)? to register as an employee$/) do
  @browser.element(class: /interaction-click-control-continue/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/))
end

Then(/^.+ should see the employee search page$/) do
  @browser.text_field(class: /interaction-field-control-person-first-name/).wait_until_present
  screenshot("employer_search")
  expect(@browser.text_field(class: /interaction-field-control-person-first-name/).visible?).to be_truthy
end 

When(/^(.*) creates an HBX account$/) do |named_person|
  person = people[named_person]

  @browser.text_field(name: "user[password_confirmation]").wait_until_present
  @browser.text_field(name: "user[email]").set(person[:email])
  @browser.text_field(name: "user[password]").set(person[:password])
  @browser.text_field(name: "user[password_confirmation]").set(person[:password])
  screenshot("create_account")
  scroll_then_click(@browser.input(value: "Create account"))
end

When(/^.+ enters? the identifying info of (.*)$/) do |named_person|
  person = people[named_person]
  @browser.text_field(class: /interaction-field-control-person-first-name/).set(person[:first_name])
  @browser.text_field(name: "person[last_name]").set(person[:last_name])
  @browser.text_field(name: "jq_datepicker_ignore_person[dob]").set(person[:dob])
  scroll_then_click(@browser.label(:text=> /FIRST NAME/))
  @browser.text_field(name: "person[ssn]").set(person[:ssn])
  @browser.radio(id: /radio_male/).fire_event("onclick")
  screenshot("information_entered")
  @browser.element(class: /interaction-click-control-continue/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/))
end

Then(/^.+ should not see the matched employee record form$/) do
  @browser.element(class: /fa-exclamation-triangle/).wait_until_present
  expect(@browser.element(class: /interaction-click-control-this-is-my-employer/).exists?).to be_falsey
end

Then(/^Employee should see the matched employee record form$/) do
  @browser.dd(text: /Acme Inc\./).wait_until_present
  screenshot("employer_search_results")
  expect(@browser.dd(text: /Acme Inc\./).visible?).to be_truthy
end

# TODO: needs to be merged
Then(/^.+ should see the matching employee record form$/) do
  @browser.element(text: /Turner Agency/).wait_until_present
  screenshot("employer_search_results")
  expect(@browser.element(text: /Turner Agency/).visible?).to be_truthy
end

When(/^.+ accepts? the matched employer$/) do
  scroll_then_click(@browser.input(value: /This is my employer/))
  @browser.input(name: "person[emails_attributes][0][address]").wait_until_present
  screenshot("update_personal_info")
end

When(/^.+ completes? the matched employee form for (.*)$/) do |named_person|
  person = people[named_person]
  scroll_then_click(@browser.element(class: /interaction-click-control-click-here/))
  @browser.button(class: /interaction-click-control-close/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-close/))
  @browser.button(class: /interaction-click-control-close/).wait_while_present

  scroll_then_click(@browser.text_field(name: "person[addresses_attributes][0][address_1]"))
  scroll_then_click(@browser.text_field(name: "person[addresses_attributes][0][address_2]"))
  scroll_then_click(@browser.text_field(name: "person[addresses_attributes][0][city]"))
  scroll_then_click(@browser.text_field(name: "person[addresses_attributes][0][zip]"))

  @browser.text_field(name: "person[phones_attributes][0][full_phone_number]").set(person[:home_phone])
  scroll_then_click(@browser.text_field(name: "person[emails_attributes][1][address]"))
  screenshot("personal_info_complete")
  @browser.button(id: /btn-continue/).wait_until_present
  scroll_then_click(@browser.button(id: /btn-continue/))
end

Then(/^.+ should see the dependents page$/) do
  @browser.a(text: /Add Member/).wait_until_present
  screenshot("dependents_page")
  expect(@browser.a(text: /Add Member/).visible?).to be_truthy
end

When(/^.+ clicks? edit on baby Soren$/) do
  scroll_then_click(@browser.span(text: "07/03/2014").as(xpath: "./preceding::a[contains(@href, 'edit')]").last)
end

Then(/^.+ should see the edit dependent form$/) do
  @browser.button(:text => /Confirm Member/).wait_until_present
end

When(/^.+ clicks? delete on baby Soren$/) do
  scroll_then_click(@browser.form(id: 'edit_dependent').a())
  @browser.div(id: 'remove_confirm').wait_until_present
  scroll_then_click(@browser.a(class: /confirm/))
  @browser.button(text: /Confirm Member/).wait_while_present
end

Then(/^.+ should see (.*) dependents*$/) do |n|
  n = n.to_i
  expect(@browser.li(class: "dependent_list", index: n)).not_to exist
  expect(@browser.li(class: "dependent_list", index: n - 1)).to exist
end

When(/^.+ clicks? Add Member$/) do
  scroll_then_click(@browser.a(text: /Add Member/))
  @browser.button(text: /Confirm Member/).wait_until_present
end

Then(/^.+ should see the new dependent form$/) do
  expect(@browser.button(text: /Confirm Member/).visible?).to be_truthy
end

When(/^.+ enters? the dependent info of Sorens daughter$/) do
  @browser.text_field(name: 'dependent[first_name]').set('Cynthia')
  @browser.text_field(name: 'dependent[last_name]').set('White')
  @browser.text_field(name: 'jq_datepicker_ignore_dependent[dob]').set('01/15/2011')
  input_field = @browser.div(class: /selectric-wrapper/)
  input_field.click
  input_field.li(text: /Child/).click
  @browser.radio(id: /radio_female/).fire_event("onclick")
end

When(/^.+ clicks? confirm member$/) do
  scroll_then_click(@browser.button(text: /Confirm Member/))
  @browser.button(text: /Confirm Member/).wait_while_present
end

When(/^.+ clicks? continue on the dependents page$/) do
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/, id: /btn-continue/))
end

Then(/^.+ should see the group selection page$/) do
  @browser.form(action: /group_selection\/create/).wait_until_present
  screenshot("group_selection")
end

When(/^.+ clicks? continue on the group selection page$/) do
  @browser.element(class: /interaction-click-control-continue/, id: /btn-continue/).wait_until_present
  @browser.execute_script("$('.interaction-click-control-continue').trigger('click')")
  #scroll_then_click(@browser.element(class: /interaction-click-control-continue/, id: /btn-continue/))
end

Then(/^.+ should see the plan shopping welcome page$/) do
  @browser.element(text: /Filter Results/i).wait_until_present
  # @browser.h3(text: /Select a Plan/).wait_until_present
  screenshot("plan_shopping_welcome")
  expect(@browser.element(text: /Choose a healthcare plan/i).visible?).to be_truthy
  # expect(@browser.h3(text: /Select a Plan/).visible?).to be_truthy
end

When(/^.+ clicks? continue on the plan shopping welcome page$/) do
  scroll_then_click(@browser.a(text: "Continue"))
end

Then(/^.+ should see the list of plans$/) do
  @browser.a(text: /Select/).wait_until_present
  screenshot("plan_shopping")
end

When(/^.+ selects? a plan on the plan shopping page$/) do
  @browser.execute_script(
    'arguments[0].scrollIntoView();',
    @browser.element(:text => /Choose a healthcare plan/)
  )
  scroll_then_click(@browser.a(text: /Select/))
end

Then(/^.+ should see the coverage summary page$/) do
  @browser.element(class: /interaction-click-control-purchase/).wait_until_present
  screenshot("summary_page")
  expect(@browser.element(text: /Confirm Your Plan Selection/i).visible?).to be_truthy
end

When(/^.+ clicks? on purchase button on the coverage summary page$/) do
  # @browser.execute_script('$(".interaction-click-control-purchase").trigger("click")')
  @browser.element(class: /interaction-click-control-purchase/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-purchase/))
end

Then(/^.+ should see the receipt page$/) do
  @browser.element(class: /interaction-click-control-continue/).wait_until_present
  screenshot("receipt_page")
  expect(@browser.element(text: /Purchase confirmation/i).visible?).to be_truthy
  @browser.element(class: /interaction-click-control-continue/).click
end

Then(/^.+ should see the "my account" page$/) do
  wait_and_confirm_text(/My DC Health Link/)
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
  @browser.element(text: /Family Members/i).wait_until_present
  expect(@browser.element(text: /Family Members/i).visible?).to be_truthy
  scroll_then_click(@browser.a(id: /btn_household_continue/))
  @browser.element(text: /Covered Family Members/i).wait_until_present
  expect(@browser.element(text: /Covered Family Members/i).visible?).to be_truthy
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
  start_on = @browser.element(class: /selectric-interaction-choice-control-plan-year-start-on/)
  click_when_present(start_on)
  click_when_present(start_on.lis()[1])
  click_when_present(@browser.element(class: /interaction-click-control-save-plan-year/))
  @browser.element(class: /alert-notice/, text: /Plan Year successfully saved./).wait_until_present
  click_when_present(@browser.element(class: /interaction-click-control-benefits/))
  click_when_present(@browser.element(class: /interaction-click-control-publish-plan-year/))
end

When(/^.+ visits? consumer profile homepage$/) do
  @browser.goto("http://localhost:3000/consumer_profiles/home")
end

Then(/^.+ should see the "YOUR LIFE EVENTS" section/) do
  @browser.element(text: /YOUR LIFE EVENTS/i).wait_until_present
  screenshot("your_life_events")
  expect(@browser.element(text: /YOUR LIFE EVENTS/i).visible?).to be_truthy
end

Then(/^.+ should see my plan/) do
  @browser.element(text: /plan name/i).wait_until_present
  screenshot("my_plan")
  expect(@browser.element(text: /plan name/i).visible?).to be_truthy
end

When(/^.+ should see a published success message$/) do
  # @browser.element(class: /mainmenu/).wait_until_present
  @browser.element(class: /interaction-click-control-get-reports/).wait_until_present
  expect(@browser.element(text: /Plan Year successfully published/).visible?).to be_truthy
end

When(/^.+ clicks? on the add employee button$/) do
  @browser.a(text: /Add Employee/).wait_until_present
  @browser.a(text: /Add Employee/).click
end

When(/^.+ clicks? on the (.+) tab$/) do |tab_name|
  @browser.a(text: /#{tab_name}/).wait_until_present
  scroll_then_click(@browser.a(text: /#{tab_name}/))
end 

When(/^.+ clicks? on the tab for (.+)$/) do |tab_name|
  @browser.element(class: /interaction-click-control-#{tab_name}/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-#{tab_name}/))
end