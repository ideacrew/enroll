# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/lib/transfer_accounts"

RSpec.describe ::FinancialAssistance::TransferAccounts, dbclean: :after_each do
  include Dry::Monads[:do, :result]
  let!(:person) { FactoryBot.create(:person, :with_ssn, hbx_id: "732020")}
  let!(:person2) { FactoryBot.create(:person, :with_ssn, hbx_id: "732021") }
  let!(:person3) { FactoryBot.create(:person, :with_ssn, hbx_id: "732022") }
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      family_id: family.id,
                      account_transferred: false,
                      transfer_requested: true,
                      assistance_year: assistance_year,
                      aasm_state: 'determined',
                      hbx_id: "830293",
                      submitted_at: Date.yesterday,
                      created_at: Date.yesterday)
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
                                  is_post_partum_period: false)
    applicant
  end

  let!(:eligibility_determination) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }

  let(:assistance_year) { FinancialAssistanceRegistry[:enrollment_dates].setting(:application_year).item.constantize.new.call.value!.to_s }
  # let!(:products) { FactoryBot.create_list(:benefit_markets_products_health_products_health_product, 5, :silver) }

  let(:premiums_hash) do
    {
      [person.hbx_id] => {:health_only => {person.hbx_id => [{:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}]}},
      [person2.hbx_id] => {:health_only => {person2.hbx_id => [{:cost => 200.0, :member_identifier => person2.hbx_id, :monthly_premium => 200.0}]}},
      [person3.hbx_id] => {:health_only => {person3.hbx_id => [{:cost => 200.0, :member_identifier => person3.hbx_id, :monthly_premium => 200.0}]}}
    }
  end

  let(:slcsp_info) do
    {
      person.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person.hbx_id, :monthly_premium => 200.0}},
      person2.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person2.hbx_id, :monthly_premium => 200.0}},
      person3.hbx_id => {:health_only_slcsp_premiums => {:cost => 200.0, :member_identifier => person3.hbx_id, :monthly_premium => 200.0}}
    }
  end

  let(:lcsp_info) do
    {
      person.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person.hbx_id, :monthly_premium => 100.0}},
      person2.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person2.hbx_id, :monthly_premium => 100.0}},
      person3.hbx_id => {:health_only_lcsp_premiums => {:cost => 100.0, :member_identifier => person3.hbx_id, :monthly_premium => 100.0}}
    }
  end

  let(:premiums_double) { double(:success => premiums_hash) }
  let(:slcsp_double) { double(:success => slcsp_info) }
  let(:lcsp_double) { double(:success => lcsp_info) }

  let(:fetch_double) { double(:new => double(call: premiums_double))}
  let(:fetch_slcsp_double) { double(:new => double(call: slcsp_double))}
  let(:fetch_lcsp_double) { double(:new => double(call: lcsp_double))}

  let(:obj)  { FinancialAssistance::Operations::Transfers::MedicaidGateway::TransferAccount.new }
  let(:event) { Success(double) }

  let(:hbx_profile) {FactoryBot.create(:hbx_profile)}
  let(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, :open_enrollment_coverage_period, hbx_profile: hbx_profile) }
  let(:benefit_coverage_period) { hbx_profile.benefit_sponsorship.benefit_coverage_periods.first }
  let(:transfer_account_obj)  { FinancialAssistance::TransferAccounts.new }
  let(:event_2) { Success(double(publish: true)) }

  before do
    allow(HbxProfile).to receive(:current_hbx).and_return hbx_profile
    allow(hbx_profile).to receive(:benefit_sponsorship).and_return benefit_sponsorship
    allow(benefit_sponsorship).to receive(:current_benefit_period).and_return(benefit_coverage_period)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(FinancialAssistance::TransferAccounts).to receive(:new).and_return(transfer_account_obj)
    allow(transfer_account_obj).to receive(:build_event).and_return(event_2)
    allow(event.success).to receive(:publish).and_return(true)
    allow(FinancialAssistance::Operations::Transfers::MedicaidGateway::TransferAccount).to receive(:new).and_return(obj)
    allow(obj).to receive(:build_event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
    stub_const('::Operations::Products::Fetch', fetch_double)
    stub_const('::Operations::Products::FetchSlcsp', fetch_slcsp_double)
    stub_const('::Operations::Products::FetchLcsp', fetch_lcsp_double)
    allow(premiums_double).to receive(:failure?).and_return(false)
    allow(slcsp_double).to receive(:failure?).and_return(false)
    allow(lcsp_double).to receive(:failure?).and_return(false)
  end

  before :each do
    Dir.glob("#{Rails.root}/log/account_transfer_logger_*.log").each do |file|
      FileUtils.rm(file)
    end
  end

  context 'only transfer once' do
    before do
      ::FinancialAssistance::TransferAccounts.run
      @file_content = File.read("#{Rails.root}/log/account_transfer_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
    end

    it 'should transfer the account the first time' do
      expect(@file_content).to include(application.hbx_id)
    end
  end

  context 'renewal applications' do
    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:block_renewal_application_transfers).and_return(true)
      application.workflow_state_transitions << WorkflowStateTransition.new(
        from_state: 'renewal_draft',
        to_state: 'submitted'
      )
      application.transfer_requested = false
      application.save!
    end

    it 'should not transfer a renewal application' do
      ::FinancialAssistance::TransferAccounts.run
      file_content = File.read("#{Rails.root}/log/account_transfer_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      expect(file_content).not_to include(application.hbx_id)
    end

  end

  context 'current or future assistance year applications' do
    it 'should send for current years even after 11/1' do
      year = TimeKeeper.date_of_record.year
      allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(year, 12, 31))
      ::FinancialAssistance::TransferAccounts.run
      file_content = File.read("#{Rails.root}/log/account_transfer_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      expect(file_content).to include(application.hbx_id)
    end
    it 'should transfer an application from a future year' do
      application.assistance_year = TimeKeeper.date_of_record.year + 1
      application.save!
      ::FinancialAssistance::TransferAccounts.run
      file_content = File.read("#{Rails.root}/log/account_transfer_logger_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log")
      expect(file_content).to include(application.hbx_id)
    end
  end

end
