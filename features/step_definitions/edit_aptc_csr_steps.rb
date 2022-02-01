# frozen_string_literal: true

Then(/^Hbx Admin sees Families link$/) do
  expect(page).to have_text("Families")
end

When(/^Hbx Admin click Families link$/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-families').click
  wait_for_ajax
  find(:xpath, "//*[@id='myTab']/li[2]/ul/li[2]/a", :wait => 10).click
  wait_for_ajax
end

When(/^Hbx Admin clicks Actions button$/) do
  find_all('.dropdown.pull-right', text: 'Actions')[0].click
end

When(/^Hbx Admin click Families dropdown/) do
  visit exchanges_hbx_profiles_path
  find('.interaction-click-control-families').click
  wait_for_ajax
end

Then(/^Hbx Admin should see an Edit APTC \/ CSR link$/) do
  find_link('Edit APTC / CSR').visible?
end

Then(/Hbx Admin clicks the Edit APTC CSR link/) do
  find_all(EditAptc.edit_aptc_csr_action).first.click
end

Then(/Hbx Admin should see individual level csr percent/) do
  expect(page.has_css?(EditAptc.csr_pct_as_integer)).to eq true
  expect(page).to have_select("csr_percentage_#{Person.first.id}", :selected => '0')
end

Given(/^User with tax household exists$/) do
  create_thh_for_family
end

Given(/Tax household member info exists for user/) do
  thm = FactoryBot.create(:tax_household_member, tax_household: Family.first.active_household.tax_households.first)
  thm.update_attributes!(family_member: Family.first.family_members.first)
  BenefitMarkets::Products::Product.first.update_attributes!(metal_level_kind: :silver)
end

When(/^Hbx Admin clicks on the Update APTC CSR button$/) do
  find_link('Edit APTC / CSR').click
end


Then(/^Hbx Admin should see cat plan error message$/) do
  wait_for_ajax
  fill_in "aptc_applied_#{@enrollment.id}", with: "23.00"
  find(".toggle_update_btn").click
  wait_for_ajax(3,2)
  expect(page).to have_content(Settings.aptc_errors.cat_plan_error)
end
