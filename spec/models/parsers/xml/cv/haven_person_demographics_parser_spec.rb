require 'rails_helper'

describe "Haven person demographics parser" do
  let(:class_name) {self.name.demodulize}
  include_examples "haven parser examples", class_name

  context "verified members" do
    it 'should get ssn' do
      subject.each_with_index do |sub, index|
        if ssn.text.present?
          expect(sub.ssn).to eq ssn[index].text.strip
        else
          expect(sub.ssn).to eq ""
        end
      end
    end

    it 'should get sex' do
      subject.each_with_index do |sub, index|
        if sex.text.present?
          expect(sub.sex).to eq sex[index].text.strip
        else
          expect(sub.sex).to eq ""
        end
      end
    end

    it 'should get birth date' do
      subject.each_with_index do |sub, index|
        if birth_date.text.present?
          expect(sub.birth_date).to eq birth_date[index].text.strip
        else
          expect(sub.birth_date).to eq ""
        end
      end
    end
  end

  context "verified member family to hash" do
    # let(:xml) {File.read(Rails.root.join("spec", "test_data", "haven_eligibility_response_payloads", "verified_1_member_family.xml"))}
    #
    # it 'should return the elements as a hash' do
    #   expect(subject.to_hash).to include(:id, :person, :person_demographics, :is_primary_applicant, :is_coverage_applicant, :is_without_assistance, :is_insurance_assistance_eligible, :is_medicaid_chip_eligible, :is_non_magi_medicaid_eligible, :magi_medicaid_monthly_household_income, :magi_medicaid_monthly_income_limit, :magi_as_percentage_of_fpl, :magi_medicaid_category, :medicaid_household_size, :is_totally_ineligible, :created_at)
    # end
  end
end
