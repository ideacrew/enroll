# frozen_string_literal: true

RSpec.shared_examples :haven_parser_examples do |class_name|
  let!(:xml) {File.read(Rails.root.join('spec', 'test_data', 'haven_eligibility_response_payloads', 'verified_3_aptc_members_1_thh_200_status.xml'))}
  let!(:subject) {"Parsers::Xml::Cv::Haven::#{class_name}".constantize.parse(xml)}
  let(:family_members)  {Nokogiri::XML(xml).css('n1|family_members')}
  let(:family_member_id)  {Nokogiri::XML(xml).xpath('//n1:family_members/n1:family_member/n1:id/n1:id')}
  let(:household_id)  {Nokogiri::XML(xml).xpath('//n1:households/n1:household/n1:id/n1:id')}
  let(:irs_group_id)  {Nokogiri::XML(xml).css('n1|household').css('n1|irs_group_id').first}
  let(:start_date)  {Nokogiri::XML(xml).css('n1|household').css('n1|start_date').first}
  let(:is_primary_applicant)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|is_primary_applicant')}
  let(:is_coverage_applicant)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|is_coverage_applicant')}
  let(:is_without_assistance)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|is_without_assistance')}
  let(:is_insurance_assistance_eligible)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|is_insurance_assistance_eligible')}
  let(:is_medicaid_chip_eligible)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|is_medicaid_chip_eligible')}
  let(:is_non_magi_medicaid_eligible)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|is_non_magi_medicaid_eligible')}
  let(:magi_medicaid_monthly_household_income)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|magi_medicaid_monthly_household_income')}
  let(:magi_medicaid_monthly_income_limit)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|magi_medicaid_monthly_income_limit')}
  let(:magi_as_percentage_of_fpl)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|magi_as_percentage_of_fpl')}
  let(:magi_medicaid_category)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|magi_medicaid_category')}
  let(:medicaid_household_size)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|medicaid_household_size')}
  let(:is_totally_ineligible)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|is_totally_ineligible')}
  let(:created_at)  {Nokogiri::XML(xml).css('n1|family_member').css('n1|created_at')}
  let(:ssn) {Nokogiri::XML(xml).css('n1|person_demographics').css('n1|ssn')}
  let(:sex) {Nokogiri::XML(xml).css('n1|person_demographics').css('n1|sex')}
  let(:birth_date) {Nokogiri::XML(xml).css('n1|person_demographics').css('n1|birth_date')}
  let(:hbx_id) {Nokogiri::XML(xml).xpath('//n1:person/n1:id/n1:id')}
  let(:person_surname) {Nokogiri::XML(xml).css('n1|person').css('n1|person_surname').css('n1|person_surname')}
  let(:person_given_name) {Nokogiri::XML(xml).css('n1|person').css('n1|person_given_name').css('n1|person_given_name')}
  let(:name_last) {Nokogiri::XML(xml).css('n1|person').css('n1|person_surname')}
  let(:name_first) {Nokogiri::XML(xml).css('n1|person').css('n1|person_given_name')}
  let(:name_full) {Nokogiri::XML(xml).css('n1|person').css('n1|name_full')}
  let(:hbx_assigned_id) {Nokogiri::XML(xml).css('n1|tax_household').css('n1|id').css('n1|id')}
  let(:primary_applicant_id) {Nokogiri::XML(xml).css('n1|tax_household').css('n1|primary_applicant_id').css('n1|id')}
  let(:start_date) {Nokogiri::XML(xml).css('n1|tax_household').css('n1|start_date')}
  let(:tax_household_members) {Nokogiri::XML(xml).css('n1|tax_household').css('n1|tax_household_members')}
  let(:integrated_case_id) {Nokogiri::XML(xml).xpath('//n1:external_verified_family/n1:id/n1:id')}
  let(:primary_family_member_id) {Nokogiri::XML(xml).css('n1|external_verified_family').css('n1|primary_family_member_id').css('n1|id')}
  let(:e_case_id) {Nokogiri::XML(xml).css('n1|family_members').css('n1|e_case_id')}
  let(:fin_app_id) {Nokogiri::XML(xml).css('n1|external_verified_family').css('n1|fin_app_id')}
  let(:haven_app_id) {Nokogiri::XML(xml).css('n1|external_verified_family').css('n1|haven_app_id')}
  let(:haven_ic_id) {Nokogiri::XML(xml).css('n1|external_verified_family').css('n1|haven_ic_id')}
  let(:tax_household_member_id) {Nokogiri::XML(xml).css('n1|tax_household_member').css('n1|id').css('n1|id')}
  let(:person_id) {Nokogiri::XML(xml).css('n1|tax_household_member').css('n1|person').css('n1|id').css('n1|id')}
  let(:person_surname) {Nokogiri::XML(xml).css('n1|tax_household_member').css('n1|person').css('n1|person_name').css('n1|person_surname')}
  let(:person_given_name) {Nokogiri::XML(xml).css('n1|tax_household_member').css('n1|person').css('n1|person_name').css('n1|person_given_name')}
  let(:is_consent_applicant) {Nokogiri::XML(xml).css('n1|tax_household_member').css('n1|is_consent_applicant')}
  let(:eligibility_determination_id) {Nokogiri::XML(xml).css('n1|eligibility_determination').css('n1|id')}
  let(:maximum_aptc) {Nokogiri::XML(xml).css('n1|eligibility_determination').css('n1|maximum_aptc')}
  let(:csr_percent) {Nokogiri::XML(xml).css('n1|eligibility_determination').css('n1|csr_percent')}
  let(:aptc_csr_annual_household_income) {Nokogiri::XML(xml).css('n1|eligibility_determination').css('n1|aptc_csr_annual_household_income')}
  let(:determination_date) {Nokogiri::XML(xml).css('n1|eligibility_determination').css('n1|determination_date')}
  let(:aptc_annual_income_limit) {Nokogiri::XML(xml).css('n1|eligibility_determination').css('n1|aptc_annual_income_limit')}
  let(:csr_annual_income_limit) {Nokogiri::XML(xml).css('n1|eligibility_determination').css('n1|csr_annual_income_limit')}
  let(:eligibility_determination_created_at) {Nokogiri::XML(xml).css('n1|eligibility_determination').css('n1|created_at')}
end