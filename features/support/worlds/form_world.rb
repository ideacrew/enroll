module FormWorld
  def fill_in_admin_create_plan_year_form
    first_element = find("#baStartDate > option:nth-child(2)").text
    select(first_element, :from => "baStartDate")
    find('#fteCount').set(5)
  end

  def fill_in_partial_create_plan_year_form
    first_element = find("#baStartDate > option:nth-child(2)").text
    select(first_element, :from => "baStartDate")
    find('#fteCount').set(5)
    find('#open_enrollment_end_on').set('')
  end

  def generate_sic_codes
    cz_pattern = Rails.root.join("db", "seedfiles", "fixtures", "sic_codes", "sic_code_*.yaml")

    Mongoid::Migration.say_with_time("Load SIC Codes") do
      Dir.glob(cz_pattern).each do |f_name|
        loaded_class_1 = ::SicCode
        yaml_str = File.read(f_name)
        data = YAML.load(yaml_str)
        data.new_record = true
        data.save!
      end
    end
  end

end

World(FormWorld)

Then(/^the Create Plan Year form will auto-populate the available dates fields$/) do
  expect(find('#end_on').value.blank?).to eq false
  expect(find('#open_enrollment_end_on').value.blank?).to eq false
  expect(find('#open_enrollment_start_on').value.blank?).to eq false
end

Then(/^the Create Plan Year form submit button will be disabled$/) do
  expect(page.find("#adminCreatePyButton")[:class].include?("disabled")).to eq true
end

Then(/^the Create Plan Year form submit button will not be disabled$/) do
  expect(page.find("#adminCreatePyButton")[:class].include?("disabled")).to eq false
end

Then(/^the Create Plan Year option row will no longer be visible$/) do
  expect(page).to_not have_css('label', text: 'Effective Start Date')
  expect(page).to_not have_css('label', text: 'Effective End Date')
  expect(page).to_not have_css('label', text: 'Full Time Employees')
  expect(page).to_not have_css('label', text: 'Open Enrollment Start Date')
  expect(page).to_not have_css('label', text: 'Open Enrollment End Date')
end

Then(/^the Effective End Date for the Create Plan Year form will be blank$/) do
  expect(find('#end_on').value.blank?).to eq true
end

Then(/^the Open Enrollment Start Date for the Create Plan Year form will be disabled$/) do
  expect(page.find("#open_enrollment_start_on")[:class].include?("blocking")).to eq true
end

Then(/^the Open Enrollment End Date for the Create Plan Year form will be disabled$/) do
  expect(page.find("#open_enrollment_end_on")[:class].include?("blocking")).to eq true
end

Then(/^the Open Enrollment Start Date for the Create Plan Year form will be enabled$/) do
  expect(page.find("#open_enrollment_start_on")[:class].include?("blocking")).to eq false
end

Then(/^the Open Enrollment End Date for the Create Plan Year form will be enabled$/) do
  expect(page.find("#open_enrollment_end_on")[:class].include?("blocking")).to eq false
end

Then(/^the Effective End Date for the Create Plan Year form will be filled in$/) do
  expect(find('#end_on').value.blank?).to eq false
end
