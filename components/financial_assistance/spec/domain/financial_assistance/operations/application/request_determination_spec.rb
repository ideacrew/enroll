# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Operations::Application::RequestDetermination, dbclean: :after_each do
  let(:family_id) { BSON::ObjectId.new }
  let!(:year) { TimeKeeper.date_of_record.year }
  let!(:application) do
    FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "draft", :medicaid_terms => true,
                                                         :submission_terms => true,
                                                         :medicaid_insurance_collection_terms => true,
                                                         :report_change_terms => true)
  end
  let!(:applicant) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: BSON::ObjectId.new, is_primary_applicant: true) }

  let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, application: application, family_member_id: BSON::ObjectId.new) }
  let(:set_up_relationships) do
    application.ensure_relationship_with_primary(applicant1, 'spouse')
    application.build_relationship_matrix
    application.save!
  end

  before do
    allow(application).to receive(:may_submit?).and_return(true)
    application.applicants.each do |appl|
      appl.citizen_status = 'alien_lawfully_present'
      appl.first_name = 'test'
      appl.last_name = 'test'
      appl.middle_name = 'test'
      appl.dob = Date.today - 30.years
      appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                         :address_1 => '1111 Awesome Street NE',
                                         :address_2 => '#111',
                                         :address_3 => '',
                                         :city => 'Washington',
                                         :country_name => '',
                                         :kind => 'home',
                                         :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                         :zip => '20001',
                                         county: '')]
      appl.save!
    end
    application.save!

    set_up_relationships
    application.reload
  end

  describe 'When Application in non submitted state passed' do
    let(:result) do
      application.update_attributes(aasm_state: 'submitted')
      subject.call(application_id: application.id)
    end

    it 'should fail with mssage' do
      expect(result.failure?).to be_truthy
      expect(result.failure).to eq "Unable to submit the application for given application hbx_id: #{application.hbx_id}, base_errors: {}"
    end
  end

  describe 'When Application with valid information given' do
    it 'should publish payload successfully' do
      result = subject.call(application_id: application.id)
      expect(result.success?).to be_truthy
    end

    context "applicant has penalty_on_early_withdrawal_of_savings deduction" do
      before do
        deduction = FactoryBot.build(:financial_assistance_deduction, kind: "penalty_on_early_withdrawal_of_savings", end_on: nil)
        application.applicants.first.deductions << deduction
      end

      it "should publish payload successfully" do
        result = subject.call(application_id: application.id)
        expect(result.success?).to be_truthy
      end
    end
  end

  describe 'When Application acceptance terms missing' do
    it 'should fail publish with schema validation errors' do
      application.update_attributes(:medicaid_terms => nil,
                                    :submission_terms => nil,
                                    :medicaid_insurance_collection_terms => nil,
                                    :report_change_terms => nil)
      result = subject.call(application_id: application.id)
      expect(result.failure?).to be_truthy
      %w[has_accepted_medicaid_terms has_accepted_medicaid_insurance_collection_terms has_accepted_submission_terms has_accepted_report_change_terms].each do |element|
        expect(result.failure.detect{|msg| msg.scan(/#{element}/)}).to be_present
      end
    end
  end

  describe "when all applicants applying coverage" do
    it 'should return success' do
      application.applicants[0..1].each{|applicant| applicant.update_attributes(is_applying_coverage: true)}
      application.applicants[2..-1].each{|applicant| applicant.update_attributes(is_applying_coverage: true)}
      result = subject.call(application_id: application.id)
      expect(result).to be_a(Dry::Monads::Result::Success)
      application.reload
      expect(application.eligibility_request_payload).not_to eq nil

      doc = Nokogiri::XML(result.success)
      doc.xpath("//xmlns:is_coverage_applicant").each do |element|
        expect(element.text).to eq 'true'
      end
    end
  end

  describe "when some applicants not applying coverage" do
    let(:conditional_elements) do
      %w[immigration_information is_incarcerated has_insurance is_self_attested_blind is_veteran has_daily_living_help has_bill_pay_3_month_help]
    end
    before do
      application.applicants[0..1].each{|applicant| applicant.update_attributes(is_applying_coverage: true)}
      application.applicants[2..-1].each{|applicant| applicant.update_attributes(is_applying_coverage: false)}
    end

    it 'should return success with skipped elements' do
      result = subject.call(application_id: application.id)
      expect(result).to be_a(Dry::Monads::Result::Success)
      application.reload
      expect(application.eligibility_request_payload).not_to eq nil

      doc = Nokogiri::XML(result.success)
      doc.xpath("//xmlns:assistance_tax_household_member").each do |element|
        if element.search('is_coverage_applicant').text == 'true'
          conditional_elements.each{|name| expect(element.search(name)).to be_present }
        else
          conditional_elements.each{|name| expect(element.search(name)).to be_empty }
        end
      end
    end
  end
end
