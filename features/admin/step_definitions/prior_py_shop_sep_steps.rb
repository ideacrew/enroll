# frozen_string_literal: true

Given(/^the Prior PY SHOP feature configuration is enabled$/) do
  enable_feature :prior_plan_year_shop_sep
end

Then(/.+ see enrollments generated in prior year and current year for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 2
end

Then(/.+ see enrollments generated only in prior year for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 1
end

Then(/.+ see enrollments generated only in terminated py for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 2
  effective_on_states = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_states).to match_array(["coverage_terminated", "coverage_terminated"])
end

Then(/.+ enrollments generated expired, active and renewing py for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 3
  effective_on_states = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_states).to match_array(["coverage_expired", "coverage_enrolled", "auto_renewing"])
end

Then(/.+ see enrollments generated in prior and current year, with active one canceled for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 3
  effective_on_states = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_states).to match_array(["coverage_canceled", "coverage_expired", "coverage_enrolled"])
end

Then(/.+ see enrollments generated in expired and active py, with existing active enr canceled and expired enr terminated for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 4
  effective_on_states = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_states).to match_array(["coverage_canceled", "coverage_enrolled", "coverage_expired", "coverage_terminated"])
end

Then(/.+ see enrollments generated in expired and active reinstated py, with existing active enr canceled and expired enr terminated for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 5
  effective_on_states = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_states).to match_array(["coverage_canceled", "coverage_terminated", "coverage_expired", "coverage_termination_pending", "coverage_selected"])
end

Then(/.+ see enrollments generated in reinstated expired and active py, with existing active enr canceled and reinstated expired enr for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 4
  effective_on_states = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_states).to match_array(["coverage_canceled", "coverage_canceled", "coverage_expired", "coverage_enrolled"])
end

Then(/.+ see enrollments generated expired, active and renewing py with existing active enr canceled and expired enr terminated for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 5
  effective_on_states = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_states).to match_array(["coverage_canceled", "coverage_terminated", "coverage_expired", "coverage_enrolled", "auto_renewing"])
end

Then(/.+ see enrollments generated expired, active and renewing py with existing active and renewal enr canceled and expired enr terminated for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 6
  effective_on_states = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_states).to match_array(["coverage_canceled", "coverage_terminated", "coverage_canceled", "coverage_expired", "coverage_enrolled", "auto_renewing"])
end

Then(/.+ see enrollments generated only in expired py with existing expired enr terminated for (.*)/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  family = person_record.primary_family
  expect(family.hbx_enrollments.count).to eq 3
  effective_on_states = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_states).to match_array(["coverage_enrolled", "coverage_expired", "coverage_terminated"])
end

And(/employee (.*) has employer sponsored enrollment in active py/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  employee_role = person_record.active_employee_roles.first
  benefit_package = @active_application.benefit_packages.first
  sponsored_benefit = benefit_package.sponsored_benefit_for('health')
  create_health_enrollment_for_employee(employee_role, benefit_package, sponsored_benefit, 'coverage_enrolled')
end

And(/^employer (.*) has (.*) benefit application$/) do |legal_name, application_status|
  @employer_profile = employer_profile(legal_name)
  effective_date = TimeKeeper.date_of_record.beginning_of_month.prev_year
  @prior_application = create_application(new_application_status: application_status.to_sym, effective_date: effective_date,
                                          recorded_rating_area: @rating_area, recorded_service_area: @service_area)

  @prior_application.update_attributes!(aasm_state: :active) if application_status == 'terminated'
  terminate_application(@prior_application, (@prior_application.end_on - 3.months).end_of_month) if application_status == 'terminated'
end

And(/employee (.*) has employer sponsored enrollment in expired, active and renewal py/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  employee_role = person_record.active_employee_roles.first
  active_benefit_package = @active_application.benefit_packages.first
  active_sponsored_benefit = active_benefit_package.sponsored_benefit_for('health')
  create_health_enrollment_for_employee(employee_role, active_benefit_package, active_sponsored_benefit, 'coverage_enrolled')
  expired_benefit_package = @prior_application.benefit_packages.first
  expired_sponsored_benefit = expired_benefit_package.sponsored_benefit_for('health')
  create_health_enrollment_for_employee(employee_role, expired_benefit_package, expired_sponsored_benefit, 'coverage_expired')
  renewal_benefit_package = @renewal_application.benefit_packages.first
  renewal_sponsored_benefit = renewal_benefit_package.sponsored_benefit_for('health')
  create_health_enrollment_for_employee(employee_role, renewal_benefit_package, renewal_sponsored_benefit, 'auto_renewing')
end

And(/employee (.*) has employer sponsored enrollment in active and expired py/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  employee_role = person_record.active_employee_roles.first
  active_benefit_package = @active_application.benefit_packages.first
  active_sponsored_benefit = active_benefit_package.sponsored_benefit_for('health')
  create_health_enrollment_for_employee(employee_role, active_benefit_package, active_sponsored_benefit, 'coverage_enrolled')
  expired_benefit_package = @prior_application.benefit_packages.first
  expired_sponsored_benefit = expired_benefit_package.sponsored_benefit_for('health')
  create_health_enrollment_for_employee(employee_role, expired_benefit_package, expired_sponsored_benefit, 'coverage_expired')
end

And(/employee (.*) has employer sponsored enrollment in terminated py/) do |named_person|
  person = people[named_person]
  person_record = Person.where(first_name: person[:first_name], last_name: person[:last_name]).last
  employee_role = person_record.active_employee_roles.first
  prior_benefit_package = @prior_application.benefit_packages.first
  prior_sponsored_benefit = prior_benefit_package.sponsored_benefit_for('health')
  create_health_enrollment_for_employee(employee_role, prior_benefit_package, prior_sponsored_benefit, 'coverage_terminated')
end

When(/^a SHOP SEP is added with a prior year effective date$/) do
  find(AddSepAction.actions_drop_down_toggle, :text => AddSepAction.actions_drop_down_text).click
  click_link(AddSepAction.add_sep_text)
  scroll_to :center
  element = find(AddSepAction.admin_comment)
  scroll_to(element, align: :bottom)
  find(AddSepAction.select_sep_reason_dropdown).click
  find(AddSepAction.select_sep_reason, text: AddSepAction.sep_reason_text).click
  fill_in AddSepAction.sep_event_date, :with => (@prior_application.end_on - 6.months).beginning_of_month
  find(AddSepAction.sep_title).click
  find(AddSepAction.select_sep_options_dropdown).click
  find(AddSepAction.select_sep_option_kind, text: AddSepAction.sep_option_kind_text).click
  fill_in AddSepAction.sep_end_on, :with => Date.today
end