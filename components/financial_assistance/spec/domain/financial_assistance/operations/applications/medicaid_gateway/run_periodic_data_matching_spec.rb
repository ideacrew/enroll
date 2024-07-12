# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::RunPeriodicDataMatching, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  include Dry::Monads[:do, :result]

  let!(:person) { FactoryBot.create(:person, hbx_id: 4_378_657_346_576) }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person, hbx_assigned_id: "10028") }
  let(:application_id) { "614cd09ca54d7584cbc9532d" }
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      id: application_id,
                      effective_date: TimeKeeper.date_of_record.beginning_of_year)
  end
  let!(:applicant) do
    applicant = FactoryBot.create(:applicant,
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  dob: person.dob,
                                  gender: person.gender,
                                  ssn: person.ssn,
                                  application: application,
                                  ethnicity: [],
                                  is_primary_applicant: true,
                                  person_hbx_id: person.hbx_id,
                                  is_self_attested_blind: false,
                                  is_applying_coverage: true,
                                  is_required_to_file_taxes: true,
                                  is_filing_as_head_of_household: true,
                                  is_pregnant: false,
                                  has_job_income: false,
                                  has_self_employment_income: false,
                                  has_unemployment_income: false,
                                  has_other_income: false,
                                  has_deductions: false,
                                  is_self_attested_disabled: true,
                                  is_physically_disabled: false,
                                  citizen_status: 'us_citizen',
                                  has_enrolled_health_coverage: false,
                                  has_eligible_health_coverage: false,
                                  has_eligible_medicaid_cubcare: false,
                                  is_claimed_as_tax_dependent: false,
                                  is_incarcerated: false,
                                  net_annual_income: 10_078.90,
                                  is_ia_eligible: true,
                                  is_post_partum_period: false)
    applicant
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let(:premiums_hash) do
    {
      [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}}
    }
  end
  let(:slcsp_info) do
    {
      person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}}
    }
  end
  let(:lcsp_info) do
    {
      person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}}
    }
  end
  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
  let(:premiums_double) { double(:success => premiums_hash) }
  let(:slcsp_double) { double(:success => slcsp_info) }
  let(:lcsp_double) { double(:success => lcsp_info) }
  let(:fetch_double) { double(:new => double(call: premiums_double))}
  let(:fetch_slcsp_double) { double(:new => double(call: slcsp_double))}
  let(:fetch_lcsp_double) { double(:new => double(call: lcsp_double))}
  let(:operation) { ::FinancialAssistance::Operations::Applications::MedicaidGateway::RunPeriodicDataMatching.new }
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_month }

  let!(:enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :with_health_product,
                      family: family,
                      kind: "individual",
                      coverage_kind: "health",
                      aasm_state: 'coverage_selected',
                      effective_on: effective_on,
                      hbx_enrollment_members: [
                        FactoryBot.build(:hbx_enrollment_member,
                                         applicant_id: family.primary_applicant.id,
                                         eligibility_date: effective_on, coverage_start_on: effective_on, is_subscriber: true)
                      ])
  end

  before :each do
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(premiums_double).to receive(:failure?).and_return(false)
    allow(slcsp_double).to receive(:failure?).and_return(false)
    allow(lcsp_double).to receive(:failure?).and_return(false)
    allow(operation).to receive(:publish_mec_check).and_return(Success())
  end

  context 'Given invalid data' do
    it 'should fail when the params are invalid' do
      invalid_id = "invalid_id"
      result = operation.call(assistance_year: invalid_id, transmittable_message_id: "f55bec40-98f1-4d1a-9336-63affe761a60")
      expect(result).not_to be_success
      expect(result.failure).to include "assistance_year param is invalid"

      result = operation.call(assistance_year: TimeKeeper.date_of_record.year, transmittable_message_id: nil)
      expect(result).not_to be_success
      expect(result.failure).to include "transmittable_message_id param is missing"
    end
  end

  context 'Given a valid application' do
    it 'should find results and run periodic matching' do
      result = operation.call(assistance_year: TimeKeeper.date_of_record.year, transmittable_message_id: "f55bec40-98f1-4d1a-9336-63affe761a60")

      expect(result).to be_success
      expect(result.success).to eq({:total_applications_published => 1})
    end

    context "should build a csv report" do
      around(:each) do |test|
        delete_existing_files
        test.run
        delete_existing_files
      end

      def delete_existing_files
        filename_pattern = /periodic_data_matching_results_me/
        csv_file_paths = Dir.glob("#{Rails.root}/**/*").select { |file| file =~ filename_pattern }
        csv_file_paths.each do |file_path|
          File.delete(file_path)
        end
      end

      it 'builds csv with headers and data' do
        operation.call(assistance_year: TimeKeeper.date_of_record.year, transmittable_message_id: "f55bec40-98f1-4d1a-9336-63affe761a60")

        filename_pattern = /periodic_data_matching_results_me/
        csv_file_paths = Dir.glob("#{Rails.root}/**/*").select { |file| file =~ filename_pattern }
        # There should be only one CSV file generated at any point.
        expect(csv_file_paths.size).to eq(1)

        csv_data = CSV.read(csv_file_paths[0])

        # validate csv has right headers
        expected_headers = %w[ApplicationHBXID FamilyHbxID MemberHbxId IsPrimaryApplicant EnrollmentHbxId EnrollmentType EnrollmentState HiosId AppliedAptc ProgramEligibility]
        expect(csv_data[0]).to eq(expected_headers)

        # validate csv has data
        expect(csv_data.length).to eq(2)

        csv_file_paths = Dir.glob("#{Rails.root}/**/*").select { |file| file =~ filename_pattern }
        csv_file_paths.each do |file_path|
          File.delete(file_path)
        end
      end

    end

    it 'should not find results with old assistance_year' do
      app = ::FinancialAssistance::Application.last
      app.assistance_year = TimeKeeper.date_of_record.year - 1
      app.save
      result = operation.call(assistance_year: TimeKeeper.date_of_record.year, transmittable_message_id: "f55bec40-98f1-4d1a-9336-63affe761a60")

      expect(result).to be_success
      expect(result.success).to eq({:total_applications_published => 0})
    end

    it 'should not find results with submitted aasm_state' do
      app = ::FinancialAssistance::Application.last
      app.aasm_state = 'submitted'
      app.save
      result = operation.call(assistance_year: TimeKeeper.date_of_record.year, transmittable_message_id: "f55bec40-98f1-4d1a-9336-63affe761a60")

      expect(result).to be_success
      expect(result.success).to eq({:total_applications_published => 0})
    end

    it 'should not find results if applicants.is_ia_eligible is false' do
      app = ::FinancialAssistance::Application.last
      application = app.applicants.last
      application.is_ia_eligible = false
      application.save
      result = operation.call(assistance_year: TimeKeeper.date_of_record.year, transmittable_message_id: "f55bec40-98f1-4d1a-9336-63affe761a60")

      expect(result).to be_success
      expect(result.success).to eq({:total_applications_published => 0})
    end

    it 'should not find results if enrollment applied_aptc_amount is 0' do
      enrollment = Family.last.hbx_enrollments.enrolled_and_renewal.last
      enrollment.applied_aptc_amount = 0
      product = enrollment.product
      product.csr_variant_id = '01'
      enrollment.save
      product.save
      result = operation.call(assistance_year: TimeKeeper.date_of_record.year, transmittable_message_id: "f55bec40-98f1-4d1a-9336-63affe761a60")

      expect(result).to be_success
      expect(result.success).to eq({:total_applications_published => 0})
    end
  end
end
