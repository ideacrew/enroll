
module Helpers



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
end
