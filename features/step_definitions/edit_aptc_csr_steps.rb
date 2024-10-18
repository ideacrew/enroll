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

And(/^Hbx Admin clicks on a family member$/) do
  find(".interaction-click-control-#{Person.all_consumer_roles.first.first_name.downcase}-#{Person.all_consumer_roles.first.last_name.downcase}").click
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

Given(/self service osse feature is enabled/) do
  year = TimeKeeper.date_of_record.year
  allow(EnrollRegistry[:aca_ivl_osse_eligibility].feature).to receive(:is_enabled).and_return(true)
  EnrollRegistry["aca_ivl_osse_eligibility_#{year - 1}"].feature.stub(:is_enabled).and_return(true)
  EnrollRegistry["aca_ivl_osse_eligibility_#{year}"].feature.stub(:is_enabled).and_return(true)
  EnrollRegistry["aca_ivl_osse_eligibility_#{year + 1}"].feature.stub(:is_enabled).and_return(true)
  allow(EnrollRegistry[:self_service_osse_subsidy].feature).to receive(:is_enabled).and_return(true)
  allow(EnrollRegistry[:individual_osse_plan_filter].feature).to receive(:is_enabled).and_return(true)
end

Given(/active enrollment is OSSE eligible with APTC/) do
  hbx = HbxEnrollment.first
  member = hbx.hbx_enrollment_members.first
  hbx.update_attributes!(applied_aptc_amount: 476)
  member.person.consumer_role.eligibilities = []
  member.person.consumer_role.eligibilities << FactoryBot.build(:ivl_osse_eligibility, :with_admin_attested_evidence, evidence_state: :approved)
  member.person.save!
end

Then(/APTC slider should show minimum 85%/) do
  wait_for_ajax
  expect(page.has_css?(EditAptc.aptc_slider)).to eq true
  expect(find(EditAptc.aptc_slider)[:min]).to eq "0.85"
end

When(/Hbx Admin enters an APTC amount below 85%/) do
  find(EditAptc.applied_aptc_field).native.clear
end

Then(/Hbx Admin should see the OSSE APTC error message/) do
  wait_for_ajax
  hbx = HbxEnrollment.all.first
  effective_on = ::Insured::Factories::SelfServiceFactory.find_enrollment_effective_on_date(TimeKeeper.date_of_record.in_time_zone('Eastern Time (US & Canada)'), hbx.effective_on).to_date
  if hbx.effective_on.year == effective_on.year
    expect(page).to have_content(Settings.aptc_errors.below_85_for_osse)
  else
    expect(page).to have_content(Settings.aptc_errors.effective_date_overflow)
  end
end
