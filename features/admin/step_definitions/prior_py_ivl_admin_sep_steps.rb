# frozen_string_literal: true

Given(/^(.*) IVL customer with no health coverage exists$/) do |named_person|
  create_or_return_named_consumer(named_person)
end

Given(/(.*) has a consumer role with expired and active enrollment$/) do |named_person|
  create_or_return_named_consumer(named_person)
  family = @person_rec.primary_family
  create_prior_and_active_ivl_enrollment_for_family(family)
end

Given(/(.*) has a consumer role with prior expired active and renewal enrollment$/) do |named_person|
  create_or_return_named_consumer(named_person)
  family = @person_rec.primary_family
  create_prior_active_and_renewal_ivl_enrollment_for_family(family)
end

Given(/^Admin IVL seps are present$/) do
  FactoryBot.create(:qualifying_life_event_kind, :medical_emergency, is_self_attested: false, market_kind: "individual", post_event_sep_in_days: 60)
end

Given(/^Admin SHOP seps are present$/) do
  FactoryBot.create(:qualifying_life_event_kind, :medical_emergency, is_self_attested: false, market_kind: "shop", post_event_sep_in_days: 60)
end


When(/^a SEP is added with a prior year effective date$/) do
  find(AddSepAction.actions_drop_down_toggle, :text => AddSepAction.actions_drop_down_text).click
  click_link(AddSepAction.add_sep_text)
  scroll_to :center
  element = find(AddSepAction.admin_comment)
  scroll_to(element, align: :bottom)
  find(AddSepAction.select_sep_reason_dropdown).click
  find(AddSepAction.select_sep_reason, text: AddSepAction.sep_reason_text).click
  fill_in AddSepAction.sep_event_date, :with => Date.today - 1.year
  find(AddSepAction.sep_title).click
  find(AddSepAction.select_sep_options_dropdown).click
  find(AddSepAction.select_sep_option_kind, text: AddSepAction.sep_option_kind_text).click
  fill_in AddSepAction.sep_end_on, :with => ''
  fill_in AddSepAction.sep_end_on, :with => Date.today
end

Then(/^I see enrollments generated in prior year and current year$/) do
  family = @person_rec.primary_family
  expect(family.hbx_enrollments.count).to eq 2
  effective_on_years = family.hbx_enrollments.map(&:effective_on).flat_map(&:year)
  expect(effective_on_years).to match_array([Date.today.year, Date.today.prev_year(1).year])
end

Then(/^I see enrollment generated only in prior year$/) do
  family = @person_rec.primary_family
  expect(family.hbx_enrollments.count).to eq 1
  effective_on_years = family.hbx_enrollments.map(&:effective_on).flat_map(&:year)
  expect(effective_on_years).to match_array([Date.today.prev_year(1).year])
end

Then(/^I see enrollments generated in prior and current year, with active one canceled$/) do
  family = @person_rec.primary_family
  family.reload
  expect(family.hbx_enrollments.count).to eq 3
  effective_on_years = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_years).to match_array(['coverage_canceled', 'coverage_selected', 'unverified'])
end

Then(/^I see enrollments generated in prior and current year, with active enr canceled and expired enr terminated$/) do
  family = @person_rec.primary_family
  family.reload
  expect(family.hbx_enrollments.count).to eq 4
  effective_on_years = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_years).to match_array(["coverage_canceled", "coverage_selected", "coverage_terminated", "unverified"])
end

Then(/^I see enrollments generated in prior, active and renewal plan years$/) do
  year = Date.today.year
  family = @person_rec.primary_family
  expect(family.hbx_enrollments.count).to eq 3
  effective_on_years = family.hbx_enrollments.map(&:effective_on).flat_map(&:year)
  expect(effective_on_years).to match_array([year - 1, year, year + 1])
end

Then(/^I see enrollments generated in prior, active and renewal plan years with renewal enrollments canceled$/) do
  family = @person_rec.primary_family
  family.reload
  expect(family.hbx_enrollments.count).to eq 6
  effective_on_years = family.hbx_enrollments.map(&:aasm_state)
  expect(effective_on_years).to match_array(["auto_renewing", "coverage_canceled", "coverage_canceled", "coverage_selected", "coverage_terminated", "unverified"])
end

Given(/^the Prior PY IVL feature configuration is enabled$/) do
  enable_feature :prior_plan_year_ivl_sep
end

And(/^Coverage renewal flag is unchecked$/) do
  uncheck AddSepAction.coverage_renewal_flag
end

And(/^Coverage renewal flag is checked$/) do
  check AddSepAction.coverage_renewal_flag
end

And(/^a SEP is submitted$/) do
  click_button AddSepAction.submit_button
end

Then(/^confirmation popup is visible$/) do
  expect(page).to have_content(AddSepAction.confirmation_text)
end

Then(/^Admin clicks confirm on popup$/) do
  find(AddSepAction.popup_confirmation).click
end

And(/^I see a SEP success message for (.*)$/) do |named_person|
  expect(page).to have_content("SEP Added for #{named_person}")
end

And(/^I see a SEP error message for (.*)$/) do |_named_person|
  expect(page).to have_content("SEP not saved. (Error: Next poss effective date out of range.)")
end