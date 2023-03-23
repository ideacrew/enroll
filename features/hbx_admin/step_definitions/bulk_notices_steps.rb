#frozen_string_literal: true

Given(/^Admin is on the new Bulk Notice view$/) do
  load 'app/models/admin/bulk_notice.rb'
  visit new_exchanges_bulk_notice_path
end

When(/^Admin selects Employer$/) do
  select 'Employer'
end

When(/^Admin selects Broker Agency$/) do
  select 'Broker Agency'
end

When(/^Admin selects General Agency$/) do
  select 'General Agency'
end

When(/^Admin fills form with (.*?) FEIN$/) do |name|
  fein = case name
         when "Employer"
           employer("ACME").fein
         when "BrokerAgency"
           broker_agency_profile("ACME").fein
         when "GeneralAgency"
           general_agency_profile("ACME").fein
         end
  fill_in "bulk-notice-audience-identifiers", with: fein
  find("body").click
end

Then(/^Admin should see (.*?) badge$/) do |name|
  hbx_id = case name
           when "Employer"
             employer("ACME").hbx_id
           when "BrokerAgency"
             broker_agency_profile("ACME").hbx_id
           when "GeneralAgency"
             general_agency_profile("ACME").hbx_id
           end
  expect(page).to have_css('span.badge', text: hbx_id)
end

When(/^Admin fills in the rest of the form$/) do
  fill_in "admin_bulk_notice_subject", with: "Subject"
  fill_in "admin_bulk_notice_body", with: "Other Content"
end

When(/^Admin clicks on Preview button$/) do
  click_on 'Preview'
end

Then(/^Admin should see the Preview Screen$/) do
  expect(page).to have_content('Preview')
end
