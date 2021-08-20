# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Factories::ApplicationFactory, type: :model do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:application) do
    FactoryBot.create(:application,
                      family_id: BSON::ObjectId.new,
                      aasm_state: "determined",
                      effective_date: TimeKeeper.date_of_record)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 40.years,
                      is_primary_applicant: true,
                      family_member_id: BSON::ObjectId.new)
  end

  let!(:applicant2) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 10.years,
                      family_member_id: BSON::ObjectId.new)
  end

  context 'duplicate' do

    context 'Should not create relationships for duplicate/new application if there are no relationship for application.' do
      before do
        factory = described_class.new(application)
        @duplicate_application = factory.create_application
      end

      it 'Should return true to match the relative and applicant ids for relationships' do
        expect(@duplicate_application.relationships.count).to eq 0
      end
    end

    context 'Should create relationships for duplicate/new application with applicants from new application.' do
      before do
        application.relationships << FinancialAssistance::Relationship.new(applicant_id: applicant2.id, relative_id: applicant.id, kind: "child")
        application.relationships << FinancialAssistance::Relationship.new(applicant_id: applicant.id, relative_id: applicant2.id, kind: "parent")
        factory = described_class.new(application)
        @duplicate_application = factory.create_application
      end

      it 'Should return true to match the relative and applicant ids for relationships' do
        expect(@duplicate_application.relationships.pluck(:relative_id)).to eq @duplicate_application.applicants.pluck(:id)
      end
    end

    context 'for application' do
      context 'for determination_http_status_code, has_eligibility_response, eligibility_response_payload & eligibility_request_payload' do
        let(:mocked_params) do
          { determination_http_status_code: 200,
            has_eligibility_response: true,
            eligibility_response_payload: { hbx_id: application.hbx_id, us_state: 'DC' }.to_json,
            eligibility_request_payload: { hbx_id: application.hbx_id, us_state: 'DC' }.to_json,
            assistance_year: TimeKeeper.date_of_record.year,
            renewal_base_year: TimeKeeper.date_of_record.year,
            effective_date: TimeKeeper.date_of_record.next_month.beginning_of_month }
        end

        before do
          application.update_attributes!(mocked_params)
          factory = described_class.new(application)
          @duplicate_application = factory.create_application
        end

        it 'should not copy determination_http_status_code' do
          expect(@duplicate_application.determination_http_status_code).to be_nil
        end

        it 'should not copy has_eligibility_response' do
          expect(@duplicate_application.has_eligibility_response).not_to eq(true)
        end

        it 'should not copy eligibility_response_payload' do
          expect(@duplicate_application.eligibility_response_payload).to be_nil
        end

        it 'should not copy eligibility_request_payload' do
          expect(@duplicate_application.eligibility_request_payload).to be_nil
        end

        it 'should not copy renewal_base_year' do
          expect(@duplicate_application.renewal_base_year).to be_nil
        end

        it 'should not copy effective_date' do
          expect(@duplicate_application.effective_date).to be_nil
        end

        it 'should not copy the older hbx_id' do
          expect(@duplicate_application.hbx_id).not_to be_nil
          expect(@duplicate_application.hbx_id).not_to eq(application.hbx_id)
        end

        it 'should not copy aasm_state' do
          expect(@duplicate_application.aasm_state).not_to be_nil
          expect(@duplicate_application.aasm_state).not_to eq(application.aasm_state)
        end

        it 'should not copy assistance_year' do
          expect(@duplicate_application.assistance_year).to be_nil
        end
      end

      context 'for predecessor_id' do
        let(:predecessor_application) do
          FactoryBot.create(:application,
                            family_id: application.family_id,
                            aasm_state: "determined",
                            effective_date: TimeKeeper.date_of_record)
        end

        let(:mocked_params) { { predecessor_id: predecessor_application.id } }

        before do
          application.update_attributes!(mocked_params)
          factory = described_class.new(application)
          @duplicate_application = factory.create_application
        end

        it 'should not copy predecessor_id' do
          expect(@duplicate_application.predecessor_id).to be_nil
        end
      end
    end

    context 'for applicant' do
      context 'for medicaid_household_size, magi_medicaid_category, magi_as_percentage_of_fpl,
               magi_medicaid_monthly_income_limit, magi_medicaid_monthly_household_income,
               is_without_assistance, is_ia_eligible, is_medicaid_chip_eligible,
               is_totally_ineligible, is_eligible_for_non_magi_reasons, is_non_magi_medicaid_eligible,
               csr_percent_as_integer & csr_eligibility_kind' do
        let(:mocked_params) do
          { medicaid_household_size: 1,
            magi_medicaid_category: 'residency',
            magi_as_percentage_of_fpl: 100,
            magi_medicaid_monthly_income_limit: 10_000.00,
            magi_medicaid_monthly_household_income: 5_000.00,
            is_without_assistance: true,
            is_ia_eligible: true,
            is_medicaid_chip_eligible: true,
            is_totally_ineligible: true,
            is_eligible_for_non_magi_reasons: true,
            is_non_magi_medicaid_eligible: true,
            csr_percent_as_integer: 94,
            csr_eligibility_kind: 'csr_94' }
        end

        before do
          applicant.update_attributes!(mocked_params)
          factory = described_class.new(application)
          duplicate_application = factory.create_application
          @duplicate_applicant = duplicate_application.applicants.first
        end

        it 'should not copy medicaid_household_size' do
          expect(@duplicate_applicant.medicaid_household_size).to be_nil
        end

        it 'should not copy magi_medicaid_category' do
          expect(@duplicate_applicant.magi_medicaid_category).to be_nil
        end

        it 'should not copy magi_as_percentage_of_fpl' do
          expect(@duplicate_applicant.magi_as_percentage_of_fpl).to be_zero
        end

        it 'should not copy magi_medicaid_monthly_income_limit' do
          expect(@duplicate_applicant.magi_medicaid_monthly_income_limit.to_f).to be_zero
        end

        it 'should not copy magi_medicaid_monthly_household_income' do
          expect(@duplicate_applicant.magi_medicaid_monthly_household_income).to be_zero
        end

        it 'should not copy is_without_assistance' do
          expect(@duplicate_applicant.is_without_assistance).not_to be_truthy
        end

        it 'should not copy is_ia_eligible' do
          expect(@duplicate_applicant.is_ia_eligible).not_to be_truthy
        end

        it 'should not copy is_medicaid_chip_eligible' do
          expect(@duplicate_applicant.is_medicaid_chip_eligible).not_to be_truthy
        end

        it 'should not copy is_totally_ineligible' do
          expect(@duplicate_applicant.is_totally_ineligible).not_to be_truthy
        end

        it 'should not copy is_eligible_for_non_magi_reasons' do
          expect(@duplicate_applicant.is_eligible_for_non_magi_reasons).not_to be_truthy
        end

        it 'should not copy is_non_magi_medicaid_eligible' do
          expect(@duplicate_applicant.is_non_magi_medicaid_eligible).not_to be_truthy
        end

        it 'should not copy csr_percent_as_integer' do
          expect(@duplicate_applicant.csr_percent_as_integer).not_to eq(mocked_params[:csr_percent_as_integer])
        end

        it 'should not copy csr_eligibility_kind' do
          expect(@duplicate_applicant.csr_eligibility_kind).not_to eq(mocked_params[:csr_eligibility_kind])
        end
      end

      context 'for net_annual_income' do
        let(:mocked_params) { { net_annual_income: 10_012.00 } }

        before do
          applicant.update_attributes!(mocked_params)
          factory = described_class.new(application)
          duplicate_application = factory.create_application
          @duplicate_applicant = duplicate_application.applicants.first
        end

        it 'should not copy net_annual_income' do
          expect(@duplicate_applicant.net_annual_income).to be_nil
        end
      end

      context 'for applicant evidences' do
        before do
          applicant.evidences << FinancialAssistance::Evidence.new(key: :esi, title: "MEC", eligibility_status: "Verified")
          factory = described_class.new(application)
          duplicate_application = factory.duplicate
          @duplicate_applicant = duplicate_application.applicants.first
        end

        it 'should not hbae evidences' do
          expect(@duplicate_applicant.evidences).to eq []
        end
      end

      context 'for claimed_as_tax_dependent_by' do
        let(:mocked_params) { { claimed_as_tax_dependent_by: BSON::ObjectId.new } }

        before do
          applicant.update_attributes!(mocked_params)
          factory = described_class.new(application)
          duplicate_application = factory.create_application
          @duplicate_applicant = duplicate_application.applicants.first
        end

        it 'should not copy claimed_as_tax_dependent_by' do
          expect(@duplicate_applicant.claimed_as_tax_dependent_by).to be_nil
        end
      end
    end
  end

  describe 'family with just one family member for create_application' do
    let!(:person11) do
      FactoryBot.create(:person,
                        :with_consumer_role,
                        :with_ssn,
                        first_name: 'Person11')
    end
    let!(:family11) { FactoryBot.create(:family, :with_primary_family_member, person: person11) }

    before do
      application.update_attributes!(family_id: family11.id)
      applicant.update_attributes!(person_hbx_id: person11.hbx_id, family_member_id: family11.primary_applicant.id)
      @new_application = described_class.new(application).create_application
    end

    it 'should return application with one applicant' do
      expect(@new_application.applicants.count).to eq(1)
    end
  end

  describe 'family with just one family member for duplicate' do
    let!(:person11) do
      FactoryBot.create(:person,
                        :with_consumer_role,
                        :with_ssn,
                        first_name: 'Person11')
    end
    let!(:family11) { FactoryBot.create(:family, :with_primary_family_member, person: person11) }

    before do
      application.update_attributes!(family_id: family11.id)
      applicant.update_attributes!(person_hbx_id: person11.hbx_id, family_member_id: family11.primary_applicant.id)
      applicant2.update_attributes!(is_active: false)
      @new_application = described_class.new(application).create_application
    end

    it 'should return application with one applicant' do
      expect(@new_application.applicants.count).to eq(1)
    end
  end

  describe 'fetch_matching_applicant' do
    context 'multiple applicants with different person_hbx_ids' do
      let!(:new_application) do
        FactoryBot.create(:application,
                          family_id: BSON::ObjectId.new,
                          aasm_state: "determined",
                          effective_date: TimeKeeper.date_of_record)
      end

      let!(:new_applicant1) do
        FactoryBot.create(:applicant,
                          application: new_application,
                          dob: TimeKeeper.date_of_record - 40.years,
                          is_primary_applicant: true,
                          family_member_id: BSON::ObjectId.new,
                          first_name: 'Test',
                          last_name: 'Last',
                          person_hbx_id: '10002')
      end

      let!(:new_applicant2) do
        FactoryBot.create(:applicant,
                          application: new_application,
                          dob: TimeKeeper.date_of_record - 40.years,
                          family_member_id: BSON::ObjectId.new,
                          first_name: 'Test',
                          last_name: 'Last',
                          person_hbx_id: '10001')
      end

      before do
        applicant.update_attributes!(person_hbx_id: '10001', first_name: 'Test', last_name: 'Last', dob: TimeKeeper.date_of_record - 40.years)
        @applicant_result = described_class.new(application).send(:fetch_matching_applicant, new_application, applicant)
      end

      it 'should return applicant that matches with the person_hbx_id' do
        expect(@applicant_result.person_hbx_id).to eq(applicant.person_hbx_id)
      end
    end
  end

  describe 'relationship' do
    context 'multiple family members' do
      let!(:person11) do
        FactoryBot.create(:person,
                          :with_consumer_role,
                          :with_ssn,
                          hbx_id: '1000001',
                          first_name: 'Primary')
      end
      let!(:family11) { FactoryBot.create(:family, :with_primary_family_member, person: person11) }
      let!(:person12) do
        per = FactoryBot.create(:person, :with_consumer_role, first_name: 'Dependent', hbx_id: '1000002')
        person11.ensure_relationship_with(per, 'child')
        per
      end
      let!(:family_member12) do
        FactoryBot.create(:family_member, family: family11, person: person12)
      end

      before do
        application.update_attributes!(family_id: family11.id)
        applicant.update_attributes!(person_hbx_id: person11.hbx_id, family_member_id: family11.primary_applicant.id)
        applicant2.destroy!
        @new_application = described_class.new(application).create_application
      end

      it 'should return relationships' do
        expect(@new_application.relationships.count).to eq(2)
      end
    end
  end

  describe 'Copy Application' do
    let!(:person_11) { FactoryBot.create(:person, :with_consumer_role, first_name: 'Person_11')}
    let!(:person_12) do
      per = FactoryBot.create(:person, :with_consumer_role, first_name: 'Person_12')
      person_11.ensure_relationship_with(per, 'spouse')
      per
    end
    let!(:family_11) { FactoryBot.create(:family, :with_primary_family_member, person: person_11)}
    let!(:family_member_12) { FactoryBot.create(:family_member, person: person_12, family: family_11)}
    let!(:application_11) { FactoryBot.create(:financial_assistance_application, family_id: family_11.id, aasm_state: 'submitted', hbx_id: "111000", effective_date: TimeKeeper.date_of_record) }
    let!(:applicant_11) do
      FactoryBot.create(:applicant,
                        application: application_11,
                        first_name: person_11.first_name,
                        dob: TimeKeeper.date_of_record - 40.years,
                        is_primary_applicant: true,
                        person_hbx_id: person_11.hbx_id,
                        family_member_id: family_11.primary_applicant.id)
    end
    let!(:applicant_12) do
      FactoryBot.create(:applicant,
                        application: application_11,
                        first_name: person_12.first_name,
                        dob: TimeKeeper.date_of_record - 10.years,
                        person_hbx_id: person_12.hbx_id,
                        is_claimed_as_tax_dependent: true,
                        claimed_as_tax_dependent_by: applicant_11.id,
                        family_member_id: family_member_12.id)
    end
    let!(:relationships) do
      application_11.ensure_relationship_with_primary(applicant_12, 'spouse')
    end

    context 'sync_family_members_with_applicants' do
      context 'New Family member added without corresponding applicant' do
        let!(:person_13) do
          per = FactoryBot.create(:person, :with_consumer_role, first_name: 'Person_13')
          person_11.ensure_relationship_with(per, 'child')
          per
        end
        let!(:family_member_13) { FactoryBot.create(:family_member, person: person_13, family: family_11)}

        before do
          @new_application_factory = described_class.new(application_11)
        end

        it 'should set family_members_changed to true on factory' do
          expect(@new_application_factory.family_members_changed).to eq false
          @new_application_factory.create_application
          expect(@new_application_factory.family_members_changed).to eq true
        end
      end

      context 'New Family member dropped with corresponding applicant' do
        before do
          family_11.remove_family_member(family_member_12.person)
          family_11.save!
          @new_application_factory = described_class.new(application_11)
        end

        it 'should set family_members_changed to true on factory' do
          expect(@new_application_factory.family_members_changed).to eq false
          @new_application_factory.create_application
          expect(@new_application_factory.family_members_changed).to eq true
        end
      end
    end

    context 'claimed_as_tax_dependent_by' do
      context 'it should populate data for claimed_as_tax_dependent_by' do
        before do
          @new_application = described_class.new(application_11).create_application
          @claimed_applicant = @new_application.applicants.where(is_claimed_as_tax_dependent: true).first
          @claiming_applicant = @new_application.applicants.find(@claimed_applicant.claimed_as_tax_dependent_by)
        end

        it 'should create applicants with correct claimed as tax dependent' do
          expect(@claimed_applicant.claimed_as_tax_dependent_by).to be_truthy
        end

        it "should match the claimed applicants's claimed_as_tax_dependent_by with claiming applicant" do
          expect(@claimed_applicant.claimed_as_tax_dependent_by).to eq(@claiming_applicant.id)
        end

        it "should match the claimed applicants's person_hbx_id with old application's claimed applicants's person_hbx_id" do
          expect(@claimed_applicant.person_hbx_id).to eq(applicant_12.person_hbx_id)
        end

        it "should match the claiming applicants's person_hbx_id with old application's claiming applicants's person_hbx_id" do
          expect(@claiming_applicant.person_hbx_id).to eq(applicant_11.person_hbx_id)
        end
      end
    end
  end

  describe 'applicant with incomes, benefits and deductions' do
    let!(:create_job_income12) do
      inc = ::FinancialAssistance::Income.new({ kind: 'wages_and_salaries',
                                                frequency_kind: 'yearly',
                                                amount: 30_000.00,
                                                start_on: TimeKeeper.date_of_record.prev_year,
                                                end_on: TimeKeeper.date_of_record.prev_month,
                                                employer_name: 'Testing employer' })
      applicant.incomes << inc
      applicant.save!
    end

    let!(:create_esi_benefit) do
      benefit = ::FinancialAssistance::Benefit.new({ kind: 'is_enrolled',
                                                     insurance_kind: 'peace_corps_health_benefits',
                                                     start_on: Date.today.prev_year,
                                                     end_on: TimeKeeper.date_of_record.prev_month })
      applicant.benefits = [benefit]
      applicant.save!
    end

    let!(:deduction) do
      deduction = ::FinancialAssistance::Deduction.new({ kind: 'deductable_part_of_self_employment_taxes',
                                                         amount: 100.00,
                                                         start_on: Date.today.prev_year,
                                                         frequency_kind: 'monthly' })
      applicant.deductions << deduction
      applicant.save!
    end

    before do
      @new_application = described_class.new(application).create_application
      @new_applicant = @new_application.applicants.first
    end

    it 'should create income for applicant' do
      expect(@new_applicant.incomes.first).not_to be_nil
      expect(@new_applicant.incomes.first.kind).to eq(applicant.incomes.first.kind)
    end

    it 'should create benefit for applicant' do
      expect(@new_applicant.benefits.first).not_to be_nil
      expect(@new_applicant.benefits.first.kind).to eq(applicant.benefits.first.kind)
    end

    it 'should create deduction for applicant' do
      expect(@new_applicant.deductions.first).not_to be_nil
      expect(@new_applicant.deductions.first.kind).to eq(applicant.deductions.first.kind)
    end
  end

  describe 'with eligibility_determinations' do
    let!(:eligibility_determination) do
      ed = FactoryBot.create(:financial_assistance_eligibility_determination, application: application)
      application.applicants.each { |applicant| applicant.write_attribute(:eligibility_determination_id, ed.id) }
    end

    before do
      @new_application = described_class.new(application).create_application
    end

    it 'should not create eligibility determination objects for newly created application' do
      expect(@new_application.eligibility_determinations.present?).to be_falsy
    end

    it 'should not set eligibilitydetermination_id for new applicants' do
      expect(@new_application.applicants.pluck(:eligibility_determination_id).compact).to be_empty
    end
  end
end
