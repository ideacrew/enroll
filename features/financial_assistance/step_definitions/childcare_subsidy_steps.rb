# frozen_string_literal: true

Given(/^the shop OSSE configuration is enabled$/) do
  enable_feature :aca_shop_osse_subsidy
  enable_feature "aca_shop_osse_subsidy_#{TimeKeeper.date_of_record.year}".to_sym
end

And(/^(.+) employer has osse eligibility$/) do |legal_name|
  employer_profile = employer_profile(legal_name)
  benefit_sponsorship = employer_profile.active_benefit_sponsorship

  result = ::Operations::Eligibilities::Osse::BuildEligibility.new.call({
                                                                          subject_gid: benefit_sponsorship.to_global_id,
                                                                          evidence_key: :osse_subsidy,
                                                                          evidence_value: true,
                                                                          effective_date: TimeKeeper.date_of_record
                                                                        })

  if result.success?
    eligibility = benefit_sponsorship.eligibilities.build(result.success.to_h)
    eligibility.save!
  end

  expect(benefit_sponsorship.eligibility_for(:osse_subsidy, TimeKeeper.date_of_record)).to be_present
end

And(/^.+ should not see OSSE eligibility details$/) do
  expect(page).not_to have_content "Does this business qualify for OSSE subsidies?"
  expect(page).not_to have_selector("input[id='agency_organization_profile_attributes_osse_eligibility_true']")
  expect(page).not_to have_selector("input[id='agency_organization_profile_attributes_osse_eligibility_false']")
end

And(/^(\w+) should see OSSE eligibility details$/) do
  expect(page).to have_content "Does this business qualify for OSSE subsidies?"
  expect(page).to have_selector("input[id='agency_organization_profile_attributes_osse_eligibility_true']")
  expect(page).to have_selector("input[id='agency_organization_profile_attributes_osse_eligibility_false']")
end

Then(/^.+ clicked save on business info form/) do
  find('.interaction-click-control-save').click
  sleep 2
end

And(/^(.+) employer should remain osse eligible$/) do |legal_name|
  employer_profile = employer_profile(legal_name)
  benefit_sponsorship = employer_profile.active_benefit_sponsorship
  expect(benefit_sponsorship.eligibility_for(:osse_subsidy, TimeKeeper.date_of_record)).to be_present
end


