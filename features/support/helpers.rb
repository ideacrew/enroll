module Helpers

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

  def enter_employer_profile(employer)
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

    enter_office_location(default_office_location)
  end
  def log_on(person, portal)
    @browser.goto("http://localhost:3000/")
    portal_class = "interaction-click-control-#{portal.downcase.gsub(/ /, '-')}"
    @browser.a(class: portal_class).wait_until_present
    @browser.a(class: portal_class).click
    @browser.element(class: /interaction-click-control-sign-in/).wait_until_present
    @browser.text_field(class: /interaction-field-control-user-email/).set(person[:email])
    @browser.text_field(class: /interaction-field-control-user-password/).set(person[:password])
    @browser.element(class: /interaction-click-control-sign-in/).click
  end
  def create_roster_employee(person)
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
end
