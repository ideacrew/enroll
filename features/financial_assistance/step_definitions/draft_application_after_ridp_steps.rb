#frozen_string_literal: true

Given(/Individual has draft application that was created by account transfer/) do
    @user = FactoryBot.create(:user)
    @person = FactoryBot.create(:person, :with_consumer_role, user: user)
    family = FactoryBot.create(:family, :with_primary_family_member, person: @person)
    @application = FactoryBot.create(:financial_assistance_application, aasm_state: 'draft', family_id: family.id, effective_date: TimeKeeper.date_of_record, transfer_id: 'SBM_123')
end

Then(/Individual fills out the personal information form/) do
    find(IvlPersonalInformation.us_citizen_or_national_yes_radiobtn).click
    find(IvlPersonalInformation.naturalized_citizen_no_radiobtn).click
    find(IvlPersonalInformation.american_or_alaskan_native_no_radiobtn).click
    find(IvlPersonalInformation.incarcerated_no_radiobtn).click
    fill_in IvlPersonalInformation.address_line_one, :with => "4900 USAA BLVD NE"
    fill_in IvlPersonalInformation.address_line_two, :with => "212"
    fill_in IvlPersonalInformation.city, :with => "Washington"
    find_all(IvlPersonalInformation.select_state_dropdown).first.click
    find_all(:xpath, "//li[contains(., '#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item}')]").last.click
    fill_in IvlPersonalInformation.zip, :with => EnrollRegistry[:enroll_app].setting(:contact_center_zip_code).item
    fill_in IvlPersonalInformation.mobile_phone, :with => "22075555555"
  end

And(/the user clicks the Continue Application button/) do
    click_link "Continue"
end

Then(/the user should see the application Family Information page for the existing draft/) do
    expect(page).to have_content 'Family Information'
end