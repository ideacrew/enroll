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

def enter_office_location(location)
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

Given(/^I do not exist as a user$/) do
end

Given(/^I have an existing employee record$/) do
end

Given(/^I have an existing person record$/) do
end

Given(/^I am employed by an employer with no published plan year$/) do
end

When(/^I go to the employee account creation page$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: "Employee Portal").wait_until_present
  screenshot("start")
  scroll_then_click(@browser.a(text: "Employee Portal"))
  @browser.a(text: "Create account").wait_until_present
  screenshot("employee_portal")
  scroll_then_click(@browser.a(text: "Create account"))
end

When(/^I enter my new account information$/) do
  @browser.text_field(name: "user[password_confirmation]").wait_until_present
  screenshot("create_account")
  @email = "swhite#{rand(100)}@example.com"
  @password = "12345678"
  @browser.text_field(name: "user[email]").set(@email)
  @browser.text_field(name: "user[password]").set(@password)
  @browser.text_field(name: "user[password_confirmation]").set(@password)
  scroll_then_click(@browser.input(value: "Create account"))
end

Then(/^I should be logged in$/) do
  @browser.a(href: /consumer.employee.search/).wait_until_present
  screenshot("logged_in_welcome")
  expect(@browser.a(href: /consumer.employee.search/).visible?).to be_truthy
end

When (/^(.*) logs? out$/) do |someone|
  sleep 2
  scroll_then_click(@browser.element(class: /interaction-click-control-logout/))
  @browser.element(class: /interaction-click-control-logout/).wait_while_present
end

Then(/^I should see the hbx home page$/) do
  @browser.element(class: /interaction-click-control-employee-portal/).wait_until_present
end

When(/^I go to register as an employee$/) do
  @browser.element(class: /interaction-click-control-continue/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/))
end

Then(/^I should see the employee search page$/) do
  @browser.text_field(class: /interaction-field-control-person-first-name/).wait_until_present
  screenshot("employer_search")
  expect(@browser.text_field(class: /interaction-field-control-person-first-name/).visible?).to be_truthy
end

def people
  {
    "Soren White" => {
      first_name: "Soren",
      last_name: "White",
      dob: "08/13/1979",
      ssn: "670991234",
      home_phone: "2025551234"
    },
    "Patrick Doe" => {
      first_name: "Patrick",
      last_name: "Doe",
      dob: "01/01/1980",
      ssn: "786120965",
    }
  }
end

When(/^I enter the identifying info of (.*)$/) do |named_person|
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

Then(/^I should not see the matched employee record form$/) do
  @browser.element(class: /fa-exclamation-triangle/).wait_until_present
  expect(@browser.element(class: /interaction-click-control-this-is-my-employer/).exists?).to be_falsey
end

Then(/^I should see the matched employee record form$/) do
  @browser.dd(text: /Acme Inc\./).wait_until_present
  screenshot("employer_search_results")
  expect(@browser.dd(text: /Acme Inc\./).visible?).to be_truthy
end
# TODO: needs to be merged
Then(/^I should see the matching employee record form$/) do
  @browser.element(text: /Turner Agency/).wait_until_present
  screenshot("employer_search_results")
  expect(@browser.element(text: /Turner Agency/).visible?).to be_truthy
end

When(/^I accept the matched employer$/) do
  scroll_then_click(@browser.input(value: /This is my employer/))
  @browser.input(name: "person[emails_attributes][0][address]").wait_until_present
  screenshot("update_personal_info")
end

When(/^I complete the matched employee form for (.*)$/) do |named_person|
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
# TODO: needs to be merged
When(/^I complete the matching employee form$/) do
  @browser.text_field(name: "person[addresses_attributes][0][address_1]").set("84 I st")
  @browser.text_field(name: "person[addresses_attributes][0][address_2]").set("Suite 201")
  @browser.text_field(name: "person[addresses_attributes][0][city]").set("Herndon")

  input_field = @browser.divs(class: "selectric-interaction-choice-control-person-addresses-attributes-0-state").first
  input_field.click
  input_field.li(text: /VA/).click
  @browser.text_field(name: "person[addresses_attributes][0][zip]").set("20171")

  @browser.text_field(name: "person[phones_attributes][0][full_phone_number]").set("2025551234")
  scroll_then_click(@browser.text_field(name: "person[emails_attributes][1][address]"))
  screenshot("personal_info_complete")
  # scroll_then_click(@browser.button(class: /interaction-click-control-continue/))  # TODO cant find interaction element
  @browser.button(id: /btn-continue/).wait_until_present
  scroll_then_click(@browser.button(id: /btn-continue/))
end


Then(/^I should see the dependents page$/) do
  @browser.a(text: /Add Member/).wait_until_present
  screenshot("dependents_page")
  expect(@browser.a(text: /Add Member/).visible?).to be_truthy
end

When(/^I click edit on baby Soren$/) do
  scroll_then_click(@browser.span(text: "07/03/2014").as(xpath: "./preceding::a[contains(@href, 'edit')]").last)
end

Then(/^I should see the edit dependent form$/) do
  @browser.button(:text => /Confirm Member/).wait_until_present
end

When(/^I click delete on baby Soren$/) do
  scroll_then_click(@browser.form(id: 'edit_dependent').a())
  @browser.div(id: 'remove_confirm').wait_until_present
  scroll_then_click(@browser.a(class: /confirm/))
  @browser.button(text: /Confirm Member/).wait_while_present
end

Then(/^I should see (.*) dependents*$/) do |n|
  n = n.to_i
  expect(@browser.li(class: "dependent_list", index: n)).not_to exist
  expect(@browser.li(class: "dependent_list", index: n - 1)).to exist
end

When(/^I click Add Member$/) do
  scroll_then_click(@browser.a(text: /Add Member/))
  @browser.button(text: /Confirm Member/).wait_until_present
end

Then(/^I should see the new dependent form$/) do
  expect(@browser.button(text: /Confirm Member/).visible?).to be_truthy
end

When(/^I enter the dependent info of Sorens daughter$/) do
  @browser.text_field(name: 'dependent[first_name]').set('Cynthia')
  @browser.text_field(name: 'dependent[last_name]').set('White')
  @browser.text_field(name: 'jq_datepicker_ignore_dependent[dob]').set('01/15/2011')
  input_field = @browser.div(class: /selectric-wrapper/)
  input_field.click
  input_field.li(text: /Child/).click
  @browser.radio(id: /radio_female/).fire_event("onclick")
end

When(/^I click confirm member$/) do
  scroll_then_click(@browser.button(text: /Confirm Member/))
  @browser.button(text: /Confirm Member/).wait_while_present
end

When(/^I click continue on the dependents page$/) do
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/, id: /btn-continue/))
end

Then(/^I should see the group selection page$/) do
  @browser.form(action: /group_selection\/create/).wait_until_present
  screenshot("group_selection")
end

When(/^I click continue on the group selection page$/) do
  @browser.element(class: /interaction-click-control-continue/, id: /btn-continue/).wait_until_present
  @browser.execute_script("$('.interaction-click-control-continue').trigger('click')")
  #scroll_then_click(@browser.element(class: /interaction-click-control-continue/, id: /btn-continue/))
end

Then(/^I should see the plan shopping welcome page$/) do
  @browser.element(text: /Filter Results/i).wait_until_present
  # @browser.h3(text: /Select a Plan/).wait_until_present
  screenshot("plan_shopping_welcome")
  expect(@browser.element(text: /Choose a healthcare plan/i).visible?).to be_truthy
  # expect(@browser.h3(text: /Select a Plan/).visible?).to be_truthy
end

When(/^I click continue on the plan shopping welcome page$/) do
  scroll_then_click(@browser.a(text: "Continue"))
end

Then(/^I should see the list of plans$/) do
  @browser.a(text: /Select/).wait_until_present
  screenshot("plan_shopping")
end

When(/^I select a plan on the plan shopping page$/) do
  @browser.execute_script(
    'arguments[0].scrollIntoView();',
    @browser.element(:text => /Choose a healthcare plan/)
  )
  scroll_then_click(@browser.a(text: /Select/))
end

Then(/^I should see the coverage summary page$/) do
  @browser.element(class: /interaction-click-control-purchase/).wait_until_present
  screenshot("summary_page")
  expect(@browser.element(text: /Confirm Your Plan Selection/i).visible?).to be_truthy
end

When(/^I click on purchase button on the coverage summary page$/) do
  # @browser.execute_script('$(".interaction-click-control-purchase").trigger("click")')
  @browser.element(class: /interaction-click-control-purchase/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-purchase/))
end

Then(/^I should see the receipt page$/) do
  @browser.element(class: /interaction-click-control-continue/).wait_until_present
  screenshot("receipt_page")
  expect(@browser.element(text: /Purchase confirmation/i).visible?).to be_truthy
  @browser.element(class: /interaction-click-control-continue/).click
end

Then(/^I should see the "my account" page$/) do
  @browser.element(text: /Your Life Events/i).wait_until_present
  screenshot("my_account_page")
  expect(@browser.element(text: /Your Life Events/i).visible?).to be_truthy
end

When(/^I click qle event$/) do
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
  @browser.element(text: /Confirm Your Plan Selection/i).wait_until_present
  expect(@browser.element(text: /Confirm Your Plan Selection/i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-purchase/))
  @browser.element(text: /Purchase confirmation/i).wait_until_present
  expect(@browser.element(text: /Purchase confirmation/i).visible?).to be_truthy
  scroll_then_click(@browser.element(class: /interaction-click-control-continue/))
  @browser.element(text: /Your PLAN/i).wait_until_present
  expect(@browser.element(text: /YOUR PLAN/i).visible?).to be_truthy
end

When(/^My employer publishes a plan year$/) do
  @browser.a(text: /Employer Portal/).wait_until_present
  scroll_then_click(@browser.a(text: /Employer Portal/))
  @browser.element(class: /interaction-field-control-user-email/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(@email)
  @browser.text_field(class: /interaction-field-control-user-password/).set(@password)
  scroll_then_click(@browser.element(class: /interaction-click-control-sign-in/))
  @browser.text_field(name: "organization[first_name]").wait_until_present
  @browser.text_field(name: "organization[first_name]").set("Soren")
  @browser.text_field(name: "organization[last_name]").set("White")
  @browser.text_field(name: "jq_datepicker_ignore_organization[dob]").set("08/13/1979")
  scroll_then_click(@browser.text_field(name: "organization[first_name]"))

  @browser.text_field(name: "organization[legal_name]").set("Acme Inc.")
  @browser.text_field(name: "organization[dba]").set("Acme Inc.")
  @browser.text_field(name: "organization[fein]").set("764141112")
  input_field = @browser.divs(class: "selectric-interaction-choice-control-organization-entity-kind").first
  input_field.click
  input_field.li(text: /C Corporation/).click
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][address_1]").set("830 I St NE")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][city]").set("Washington")
  input_field = @browser.divs(class: "selectric-interaction-choice-control-organization-office-locations-attributes-0-address-attributes-state").first
  input_field.click
  input_field.li(text: /DC/).click
  @browser.select_list(name: "organization[office_locations_attributes][0][address_attributes][state]").select("DC")
  @browser.text_field(name: "organization[office_locations_attributes][0][address_attributes][zip]").set("20002")
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][area_code]").set("202")
  @browser.text_field(name: "organization[office_locations_attributes][0][phone_attributes][number]").set("5551212")
  scroll_then_click(@browser.button(class: "interaction-click-control-create-employer"))
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

When(/^I log in to the employee account page$/) do
  @browser.a(text: /Employee Portal/).wait_until_present
  scroll_then_click(@browser.a(text: /Employee Portal/))
  @browser.element(class: /interaction-field-control-user-email/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(@email)
  @browser.text_field(class: /interaction-field-control-user-password/).set(@password)
  scroll_then_click(@browser.element(class: /interaction-click-control-sign-in/))
end

When(/^I visit consumer profile homepage$/) do
  visit "/consumer_profiles/home"
end

Then(/^I should see the "YOUR LIFE EVENTS" section/) do
  @browser.element(text: /YOUR LIFE EVENTS/i).wait_until_present
  screenshot("your_life_events")
  expect(@browser.element(text: /YOUR LIFE EVENTS/i).visible?).to be_truthy
end

When(/^I click on the plans tab$/) do
  @browser.element(class: /interaction-click-control-plans/).wait_until_present
  scroll_then_click(@browser.element(class: /interaction-click-control-plans/))
end

Then(/^I should see my plan/) do
  @browser.element(text: /plan name/i).wait_until_present
  screenshot("my_plan")
  expect(@browser.element(text: /plan name/i).visible?).to be_truthy
end

When(/^I should see a published success message$/) do
  @browser.element(class: /mainmenu/).wait_until_present
  expect(@browser.element(text: /Plan Year successfully published/).visible?).to be_truthy
end
