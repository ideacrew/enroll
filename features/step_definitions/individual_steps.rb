When(/^\w+ visits? the Insured portal$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: /consumer\/family portal/i).wait_until_present
  @browser.a(text: /consumer\/family portal/i).click
  screenshot("individual_start")
end

Then(/Individual creates HBX account$/) do
  @browser.button(class: /interaction-click-control-create-account/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(@u.email :email1)
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  @browser.text_field(class: /interaction-field-control-user-password-confirmation/).set("aA1!aA1!aA1!")
  screenshot("create_account")
  scroll_then_click(@browser.input(value: "Create account"))
end

And(/user should see your information page$/) do

  click_when_present(@browser.a(class: /interaction-click-control-continue/))
end

When(/user goes to register as an individual$/) do
  @browser.button(class: /interaction-click-control-continue/).wait_until_present
  @browser.text_field(class: /interaction-field-control-person-first-name/).set("Taylor")
  @browser.text_field(class: /interaction-field-control-person-middle-name/).set("K")
  @browser.text_field(class: /interaction-field-control-person-last-name/).set(@u.last_name :last_name1)
  @browser.p(text: /suffix/i).click
  suffix = @browser.element(class: /selectric-scroll/)
  suffix.wait_until_present
  suffix = @browser.element(class: /selectric-scroll/)
  suffix.li(text: /Jr./).click
  @browser.text_field(class: /interaction-field-control-jq-datepicker-ignore-person-dob/).set(@u.adult_dob)
  @browser.h1(class: /darkblue/).click
  @browser.text_field(class: /interaction-field-control-person-ssn/).set(@u.ssn :ssn1)
  @browser.text_field(class: /interaction-field-control-person-ssn/).click
  expect(@browser.text_field(class: /interaction-field-control-person-ssn/).value).to_not eq("")
  @browser.checkbox(class: /interaction-choice-control-value-person-no-ssn/).fire_event("onclick")
  expect(@browser.text_field(class: /interaction-field-control-person-ssn/).value).to eq("")
  @browser.text_field(class: /interaction-field-control-person-ssn/).set(@u.ssn :ssn1)
  @browser.radio(class: /interaction-choice-control-value-radio-male/).fire_event("onclick")
  screenshot("register")
end

Then(/^user should see button to continue as an individual/) do
  @browser.a(text: /continue/i).wait_until_present
  screenshot("no_match")
  expect(@browser.a(text: /continue/i).visible?).to be_truthy
end

Then(/Individual should click on Individual market for plan shopping/) do
  @browser.a(text: /continue/i).wait_until_present
  @browser.a(text: /continue/i).click
end

Then(/Individual should see a form to enter personal information$/) do
  @browser.button(class: /interaction-click-control-continue/).wait_until_present
  screenshot("personal_form_top")
  @browser.radio(class: /interaction-choice-control-value-person-us-citizen-true/).fire_event("onclick")
  @browser.radio(class: /interaction-choice-control-value-person-naturalized-citizen-false/).wait_while_present
  @browser.radio(class: /interaction-choice-control-value-person-naturalized-citizen-false/).fire_event("onclick")
  @browser.radio(class: /interaction-choice-control-value-radio-incarcerated-no/).wait_while_present
  @browser.radio(class: /interaction-choice-control-value-radio-incarcerated-no/).fire_event("onclick")
  @browser.radio(class: /interaction-choice-control-value-indian-tribe-member-no/).wait_while_present
  @browser.radio(class: /interaction-choice-control-value-indian-tribe-member-no/).fire_event("onclick")
  @browser.text_field(class: /interaction-field-control-person-addresses-attributes-0-address-1/).set("4900 USAA BLVD")
  @browser.text_field(class: /interaction-field-control-person-addresses-attributes-0-address-2/).set("Suite 220")
  @browser.text_field(class: /interaction-field-control-person-addresses-attributes-0-city/).set("Washington")
  @browser.p(text: /GA/).fire_event("onclick") if @browser.p(text: /GA/).present?
  @browser.p(text: /SELECT STATE/).fire_event("onclick") if @browser.p(text: /SELECT STATE/).present?
  scroll_then_click(@browser.li(text: /DC/, class: /interaction-choice-control-state-id-9/))
  @browser.text_field(class: /interaction-field-control-person-addresses-attributes-0-zip/).set("20002")
  @browser.text_field(class: /interaction-field-control-person-phones-attributes-0-full-phone-number/).set("1110009999")
  @browser.text_field(class: /interaction-field-control-person-emails-attributes-0-address/).set(@u.find :email1)
  screenshot("personal_form_bottom")
end

When(/Individual clicks on Save and Exit/) do
   click_when_present(@browser.link(class: /interaction-click-control-save---exit/))
end

When(/^\w+ clicks? on continue button$/) do
  click_when_present(@browser.button(class: /interaction-click-control-continue/))
end

Then (/Individual resumes enrollment/) do
  @browser.a(text: /consumer\/family portal/i).wait_until_present
  @browser.a(text: /consumer\/family portal/i).click
  wait_and_confirm_text(/Sign In Existing Account/)
  click_when_present(@browser.link(class: /interaction-click-control-sign-in-existing-account/))
  sleep 2
  @browser.text_field(class: /interaction-field-control-user-email/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(@u.find :email1)
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  @browser.element(class: /interaction-click-control-sign-in/).click
  sleep(2)
  expect(@browser.text_field(class: /interaction-field-control-person-addresses-attributes-0-address-1/).value).to eq("4900 USAA BLVD")
end

Then(/^\w+ should see identity verification page and clicks on submit/) do
  @browser.label(for: /agreement_agree/).wait_until_present
  @browser.label(for: /agreement_agree/).click
  @browser.a(class: /interaction-click-control-continue/).wait_until_present
  @browser.a(class: /interaction-click-control-continue/).click
  @browser.label(for: /interactive_verification_questions_attributes_0_response_id_a/).wait_until_present
  @browser.label(for: /interactive_verification_questions_attributes_0_response_id_a/).fire_event("onclick")
  @browser.label(for: /interactive_verification_questions_attributes_1_response_id_c/).fire_event("onclick")
  @browser.button(class: /interaction-click-control-submit/).wait_until_present
  @browser.button(class: /interaction-click-control-submit/).click
  screenshot("identify_verification")
  @browser.a(class: /interaction-click-control-override-identity-verification/).wait_until_present
  screenshot("override")
  @browser.a(class: /interaction-click-control-override-identity-verification/).click
end

Then(/\w+ should see the dependents form/) do
  @browser.a(text: /Add Member/).wait_until_present
  screenshot("dependents")
  expect(@browser.a(text: /Add Member/).visible?).to be_truthy
end

And(/Individual clicks on add member button/) do
  @browser.a(text: /Add Member/).wait_until_present
  @browser.a(text: /Add Member/).click
  @browser.text_field(id: /dependent_first_name/).wait_until_present
  @browser.text_field(id: /dependent_first_name/).set("Mary")
  @browser.text_field(id: /dependent_middle_name/).set("K")
  @browser.text_field(id: /dependent_last_name/).set("York")
  @browser.text_field(name: 'jq_datepicker_ignore_dependent[dob]').set('01/15/1991')
  @browser.text_field(id: /dependent_ssn/).set(@u.ssn)
  input_field = @browser.div(class: /selectric-wrapper/)
  input_field.click
  input_field.li(text: /Domestic Partner/i).click
  @browser.radio(id: /radio_female/).fire_event("onclick")
  @browser.radio(id: /dependent_us_citizen_true/).fire_event("onclick")
  @browser.radio(id: /dependent_naturalized_citizen_false/).wait_while_present
  @browser.radio(id: /dependent_naturalized_citizen_false/).fire_event("onclick")
  @browser.radio(id: /radio_incarcerated_no/i).wait_while_present
  @browser.radio(id: /radio_incarcerated_no/i).fire_event("onclick")
  @browser.radio(id: /indian_tribe_member_no/i).wait_while_present
  @browser.radio(id: /indian_tribe_member_no/i).fire_event("onclick")
  screenshot("add_member")
  scroll_then_click(@browser.button(text: /Confirm Member/i))
  @browser.button(text: /Confirm Member/i).wait_while_present
end

And(/Individual again clicks on add member button/) do
  @browser.a(text: /Add Member/i).wait_until_present
  @browser.a(text: /Add Member/i).click
  @browser.text_field(id: /dependent_first_name/).wait_until_present
  @browser.text_field(id: /dependent_first_name/).set("Robert")
  @browser.text_field(id: /dependent_middle_name/).set("K")
  @browser.text_field(id: /dependent_last_name/).set("York")
  @browser.text_field(name: 'jq_datepicker_ignore_dependent[dob]').set('01/15/2013')
  @browser.text_field(id: /dependent_ssn/).set(@u.ssn)
  input_field = @browser.div(class: /selectric-wrapper/)
  input_field.click
  input_field.li(text: /Child/).click
  @browser.radio(id: /radio_male/).fire_event("onclick")
  @browser.radio(id: /dependent_us_citizen_true/).fire_event("onclick")
  @browser.radio(id: /dependent_naturalized_citizen_false/).wait_while_present
  @browser.radio(id: /dependent_naturalized_citizen_false/).fire_event("onclick")
  @browser.radio(id: /radio_incarcerated_no/i).wait_while_present
  @browser.radio(id: /radio_incarcerated_no/i).fire_event("onclick")
  @browser.radio(id: /indian_tribe_member_no/i).wait_while_present
  @browser.radio(id: /indian_tribe_member_no/i).fire_event("onclick")
  scroll_then_click(@browser.button(text: /Confirm Member/i))
  @browser.button(text: /Confirm Member/i).wait_while_present
end


And(/I click on continue button on household info form/) do
  click_when_present(@browser.a(text: /continue/i))
end

And(/I click on continue button on group selection page/) do
  if !HbxProfile.current_hbx.under_open_enrollment?
    click_when_present(@browser.a(text: /Had a baby/))
    @browser.text_field(id: /qle_date/).wait_until_present
    @browser.text_field(id: /qle_date/).set(5.days.ago.strftime('%m/%d/%Y'))
    click_when_present @browser.a(class: 'ui-state-default')
    wait_and_confirm_text(/CONTINUE/)
    click_when_present @browser.a(class: 'interaction-click-control-continue')
    wait_and_confirm_text /SELECT EFFECTIVE DATE/i
    effective_field = @browser.div(class: /selectric-wrapper/, text: /SELECT EFFECTIVE DATE/i)
    click_when_present(effective_field)
    effective_field.li(index: 1).click
    @browser.div(class: /success-info/).wait_until_present
    sleep 1
    @browser.div(class: /success-info/).button(class: /interaction-click-control-continue/).fire_event("onclick")
  end
  click_when_present(@browser.button(class: /interaction-click-control-continue/))
end

And(/I select a plan on plan shopping page/) do
  screenshot("plan_shopping")
  click_when_present(@browser.a(text: /Select Plan/))
end

And(/I click on purchase button on confirmation page/) do
  click_when_present(@browser.checkbox(class: /interaction-choice-control-value-terms-check-thank-you/))
  @browser.text_field(class: /interaction-field-control-first-name-thank-you/).set("Taylor")
  @browser.text_field(class: /interaction-field-control-last-name-thank-you/).set(@u.find :last_name1)
  screenshot("purchase")
  click_when_present(@browser.a(text: /confirm/i))
end

And(/I click on continue button to go to the individual home page/) do
  click_when_present(@browser.a(text: /go to my account/i))
end

And(/I should see the individual home page/) do
  @browser.element(text: /my dc health link/i).wait_until_present
  screenshot("my_account")
  click_when_present(@browser.a(class: /interaction-click-control-documents/))
  expect(@browser.element(text: /Documents/i).visible?).to be_truthy
  click_when_present(@browser.a(class: /interaction-click-control-manage-family/))
  expect(@browser.element(text: /manage family/i).visible?).to be_truthy
  click_when_present(@browser.a(class: /interaction-click-control-my-dc-health-link/))
  expect(@browser.element(text: /my dc health link/i).visible?).to be_truthy
end

And(/I click to see my Secure Purchase Confirmation/) do
  wait_and_confirm_text /Messages/
  @browser.link(text: /Messages/).click
  wait_and_confirm_text /Your Secure Enrollment Confirmation/
end

Then(/Second user creates an individual account$/) do
  @browser.button(class: /interaction-click-control-create-account/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(@u.email :email2)
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  @browser.text_field(class: /interaction-field-control-user-password-confirmation/).set("aA1!aA1!aA1!")
  screenshot("create_account")
  scroll_then_click(@browser.input(value: "Create account"))
end

Then(/^Second user goes to register as individual/) do
  step "user should see your information page"
  step "user goes to register as an individual"
  @browser.text_field(class: /interaction-field-control-person-first-name/).set("Second")
  @browser.text_field(class: /interaction-field-control-person-ssn/).set(@u.ssn :ssn2)
end

Then(/^Second user should see a form to enter personal information$/) do
  step "Individual should see a form to enter personal information"
  @browser.text_field(class: /interaction-field-control-person-emails-attributes-0-address/).set(@u.email :email2)
end

Then(/Second user asks for help$/) do
  @browser.divs(text: /Help me sign up/).last.click
  wait_and_confirm_text /Options/
  click_when_present(@browser.a(class: /interaction-click-control-help-from-a-customer-service-representative/))
  @browser.text_field(class: /interaction-field-control-help-first-name/).set("Sherry")
  @browser.text_field(class: /interaction-field-control-help-last-name/).set("Buckner")
  screenshot("help_from_a_csr")
  @browser.div(id: 'search_for_plan_shopping_help').click
  @browser.button(class: 'close').click
end

And(/^.+ clicks? the continue button$/i) do
  click_when_present(@browser.a(text: /continue/i))
end

Then(/^.+ sees the Verify Identity Consent page/)  do
  wait_and_confirm_text(/Verify Identity/)
end

When(/^CSR accesses the HBX portal$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: /hbx portal/i).wait_until_present
  @browser.a(text: /hbx portal/i).click
  wait_and_confirm_text(/Sign In Existing Account/)
  click_when_present(@browser.link(class: /interaction-click-control-sign-in-existing-account/))
  sleep 2
  @browser.text_field(class: /interaction-field-control-user-email/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set("sherry.buckner@dc.gov")
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  @browser.element(class: /interaction-click-control-sign-in/).click
  sleep 1

end

Then(/CSR should see the Agent Portal/) do
  wait_and_confirm_text /a Trained Expert/
end

Then(/CSR opens the most recent Please Contact Message/) do
  wait_and_confirm_text /Please contact/
  sleep 1
  tr=@browser.trs(text: /Please contact/).last
  scroll_then_click(tr.a(text: /show/i))
end

Then(/CSR clicks on Resume Application via phone/) do
  wait_and_confirm_text /Assist Customer/
  @browser.a(text: /Assist Customer/).fire_event('onclick')
end

When(/I click on the header link to return to CSR page/) do
  wait_and_confirm_text /Trained/
  @browser.a(text: /I'm a Trained Expert/i).click
end

Then(/CSR clicks on New Consumer Paper Application/) do
  click_when_present(@browser.a(text: /New Consumer Paper Application/i))
end

Then(/CSR starts a new enrollment/) do
  wait_and_confirm_text /Personal Information/
  wait_and_confirm_text /15% Complete/
end

Then(/^click continue again$/) do
  wait_and_confirm_text /continue/i
  sleep(1)
  scroll_then_click(@browser.a(text: /continue/i))
end

Given(/^\w+ visits the Employee portal$/) do
  @browser.goto("http://localhost:3000/")
  @browser.a(text: /employee portal/i).wait_until_present
  screenshot("start")
  scroll_then_click(@browser.a(text: /employee portal/i))
  @browser.button(text: "Create account").wait_until_present
end

Then(/^(\w+) creates a new account$/) do |person|
  @browser.button(class: /interaction-click-control-create-account/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(@u.email 'email' + person)
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  @browser.text_field(class: /interaction-field-control-user-password-confirmation/).set("aA1!aA1!aA1!")
  scroll_then_click(@browser.input(value: "Create account"))
end

When(/^\w+ clicks continue$/) do
  click_when_present(@browser.button(class: /interaction-click-control-continue/))
end

When(/^\w+ selects Company match for (\w+)$/) do |company|
  @browser.dd(text: /#{company}/).wait_until_present
  expect(@browser.dd(text: /#{company}/).visible?).to be_truthy
  scroll_then_click(@browser.input(value: /This is my employer/))
end

When(/^\w+ sees the (.*) page$/) do |title|
  wait_and_confirm_text /#{title}/
end

When(/^\w+ visits the Consumer portal$/i) do
  step "I visit the Insured portal"
end

When(/^(\w+) signs in$/) do |person|
  wait_and_confirm_text /Sign in/i
  scroll_then_click(@browser.a(text: /Sign In/i))
  @browser.h1(text: /Sign In/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set(@u.find 'email' + person)
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  scroll_then_click(@browser.input(value: "Sign in"))
end

Given(/^Company Tronics is created with benefits$/) do
  step "I visit the Employer portal"
  step "Tronics creates an HBX account"
  step "Tronics should see a successful sign up message"
  step "I should click on employer portal"
  step "Tronics creates a new employer profile"
  step "Tronics creates and publishes a plan year"
  step "Tronics should see a published success message without employee"
end

Then(/^(\w+) enters person search data$/) do |insured|
  step "#{insured} sees the Personal Information page"
  person = people[insured]
  @browser.text_field(name: "person[first_name]").wait_until_present
  @browser.text_field(name: "person[first_name]").set(person[:first_name])
  @browser.text_field(name: "person[last_name]").set(person[:last_name])
  @browser.text_field(class: /interaction-field-control-jq-datepicker-ignore-person-dob/).set(person[:dob])
  @browser.text_field(name: "person[first_name]").click
  @browser.text_field(name: "person[ssn]").set(person[:ssn])
  @browser.radio(id: /radio_female/).fire_event("onclick")
  @browser.button(text: /continue/i).fire_event("onclick")
end

Then(/^\w+ continues$/) do
  wait_and_confirm_text /Continue/i
  @browser.a(text: /Continue/i).fire_event("onclick")
end

Then(/^\w+ continues again$/) do
  wait_and_confirm_text /Continue/i
  @browser.button(text: /Continue/i).fire_event("onclick")
end

Then(/^\w+ enters demographic information$/) do
  step "Individual should see a form to enter personal information"
  @browser.text_field(class: /interaction-field-control-person-emails-attributes-0-address/).set("user#{rand(1000)}@example.com")
end

And(/^\w+ is an Employee$/) do
  wait_and_confirm_text /Employer/i
end

And(/^\w+ is a Consumer$/) do
  wait_and_confirm_text /Verify Identity/i
end

And(/(\w+) clicks on the purchase button on the confirmation page/) do |insured|
  person = people[insured]
  click_when_present(@browser.checkbox(class: /interaction-choice-control-value-terms-check-thank-you/))
  @browser.text_field(class: /interaction-field-control-first-name-thank-you/).set(person[:first_name])
  @browser.text_field(class: /interaction-field-control-last-name-thank-you/).set(person[:last_name])
  screenshot("purchase")
  click_when_present(@browser.a(text: /confirm/i))
end


Then(/^Aptc user create consumer role account$/) do
  @browser.button(class: /interaction-click-control-create-account/).wait_until_present
  @browser.text_field(class: /interaction-field-control-user-email/).set("aptc@dclink.com")
  @browser.text_field(class: /interaction-field-control-user-password/).set("aA1!aA1!aA1!")
  @browser.text_field(class: /interaction-field-control-user-password-confirmation/).set("aA1!aA1!aA1!")
  screenshot("aptc_create_account")
  scroll_then_click(@browser.input(value: "Create account"))
end

Then(/^Aptc user goes to register as individual/) do
  step "user should see your information page"
  step "user goes to register as an individual"
  @browser.text_field(class: /interaction-field-control-person-first-name/).set("Aptc")
  @browser.text_field(class: /interaction-field-control-person-ssn/).set(@u.ssn :ssn3)
  screenshot("aptc_register")

end

Then(/^Aptc user should see a form to enter personal information$/) do
  step "Individual should see a form to enter personal information"
  @browser.text_field(class: /interaction-field-control-person-emails-attributes-0-address/).set("aptc@dclink.com")
  screenshot("aptc_personal")
end

Then(/^Prepare taxhousehold info for aptc user$/) do
  person = User.find_by(email: 'aptc@dclink.com').person
  household = person.primary_family.latest_household

  start_on = TimeKeeper.date_of_record + 3.months

  if household.tax_households.blank?
    household.tax_households.create(is_eligibility_determined: TimeKeeper.date_of_record, allocated_aptc: 100, effective_starting_on: start_on, submitted_at: TimeKeeper.date_of_record)
    fm_id = person.primary_family.family_members.last.id
    household.tax_households.last.tax_household_members.create(applicant_id: fm_id, is_ia_eligible: true, is_medicaid_chip_eligible: true, is_subscriber: true)
    household.tax_households.last.eligibility_determinations.create(max_aptc: 80, determined_on: Time.now, csr_percent_as_integer: 40)
  end

  screenshot("aptc_householdinfo")
end

And(/Aptc user set elected amount and select plan/) do
  @browser.text_field(id: /elected_aptc/).wait_until_present
  @browser.text_field(id: "elected_aptc").set("20")

  click_when_present(@browser.a(text: /Select Plan/))
  screenshot("aptc_setamount")
end

Then(/Aptc user should see aptc amount and click on confirm button on thanyou page/) do
  click_when_present(@browser.checkbox(class: /interaction-choice-control-value-terms-check-thank-you/))
  expect(@browser.td(text: "$20.00").visible?).to be_truthy
  @browser.checkbox(id: "terms_check_thank_you").set(true)
  @browser.text_field(class: /interaction-field-control-first-name-thank-you/).set("Aptc")
  @browser.text_field(class: /interaction-field-control-last-name-thank-you/).set(@u.find :last_name1)
  screenshot("aptc_purchase")
  click_when_present(@browser.a(text: /confirm/i))
end

Then(/Aptc user should see aptc amount on receipt page/) do
  @browser.h1(text: /Enrollment Submitted/).wait_until_present
  expect(@browser.td(text: "$20.00").visible?).to be_truthy
  screenshot("aptc_receipt")

end

Then(/Aptc user should see aptc amount on individual home page/) do
  @browser.h1(text: /My DC Health Link/).wait_until_present
  expect(@browser.strong(text: "$20.00").visible?).to be_truthy
  expect(@browser.label(text: /APTC AMOUNT/).visible?).to be_truthy
  screenshot("aptc_ivl_home")

end
