# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Factories::ApplicationFactory, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  let!(:person1) { FactoryBot.create(:person, :with_consumer_role, first_name: 'Person_11')}
  let!(:person2) do
    per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 30.years)
    person1.ensure_relationship_with(per, 'spouse')
    person1.save!
    per
  end
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person1)}
  let!(:family_member_12) { FactoryBot.create(:family_member, person: person2, family: family)}

  let!(:application) do
    FactoryBot.create(:application,
                      family_id: family.id,
                      aasm_state: "determined",
                      effective_date: TimeKeeper.date_of_record)
  end

  let!(:applicant) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 40.years,
                      is_primary_applicant: true,
                      family_member_id: family.family_members[0].id,
                      person_hbx_id: person1.hbx_id)
  end

  let!(:applicant2) do
    FactoryBot.create(:applicant,
                      application: application,
                      dob: TimeKeeper.date_of_record - 10.years,
                      family_member_id: family_member_12.id,
                      person_hbx_id: person2.hbx_id)
  end

  context 'duplicate' do

    context 'Should create relationships if there are no relationship for application and relationships present to primary person' do
      before do
        factory = described_class.new(application)
        @duplicate_application = factory.create_application
      end

      it 'Should return true to match the relative and applicant ids for relationships' do
        expect(@duplicate_application.relationships.count).to eq 2
      end
    end

    context 'Should create relationships for duplicate/new application with applicants from new application.' do
      before do
        application.relationships << FinancialAssistance::Relationship.new(applicant_id: applicant2.id, relative_id: applicant.id, kind: "child")
        application.relationships << FinancialAssistance::Relationship.new(applicant_id: applicant.id, relative_id: applicant2.id, kind: "parent")
        application.save!
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

      context 'for applicant esi evidence' do
        before do
          applicant.build_esi_evidence(key: :esi, title: "ESI MEC")
          applicant.save!
          factory = described_class.new(application)
          duplicate_application = factory.create_application
          @duplicate_applicant = duplicate_application.applicants.first
        end

        it 'should not have esi evidence' do
          expect(@duplicate_applicant.esi_evidence).to eq nil
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

      context 'New Family member dropped with corresponding applicants' do
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

      context 'Exisitng Family Member data need to be in sync with applicants' do
        it 'should update existing applicants with updated info' do
          person_11.person_relationships.last.update_attributes(kind: 'child')

          expect(application_11.applicants.where(person_hbx_id: person_11.hbx_id).first.dob).not_to eq person_11.dob
          expect(application_11.applicants.where(person_hbx_id: person_12.hbx_id).first.relation_with_primary).to eq "spouse"
          expect(person_11.find_relationship_with(person_12)).to eq "child"

          @new_application_factory = described_class.new(application_11)
          new_application = @new_application_factory.create_application
          expect(new_application.applicants.where(person_hbx_id: person_11.hbx_id).first.dob).to eq person_11.dob
          expect(new_application.applicants.where(person_hbx_id: person_12.hbx_id).first.relation_with_primary).to eq "child"
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

    context 'is_living_in_state' do
      before :each do
        [application_11].each do |applin|
          applin.applicants.first.update_attributes!(is_primary_applicant: true)
          address_attributes = {
            kind: 'home',
            address_1: '3 Awesome Street',
            address_2: '#300',
            city: FinancialAssistanceRegistry[:enroll_app].setting(:contact_center_city).item,
            state: FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
            zip: FinancialAssistanceRegistry[:enroll_app].setting(:contact_center_zip_code).item
          }
          if EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item == 'county'
            address_attributes.merge!(
              county: FinancialAssistanceRegistry[:enroll_app].setting(:contact_center_county).item
            )
          end

          applin.reload
          applin.applicants.each do |applicant|
            applicant.addresses << ::FinancialAssistance::Locations::Address.new(address_attributes)
            applicant.save!
          end
          family_id = applin.family_id
          family = Family.find(family_id) if family_id.present?
          family.family_members.each do |fm|
            main_app_address = Address.new(address_attributes)
            fm.person.addresses << main_app_address
            fm.person.save!
          end
        end
      end

      context 'for in state addresses' do
        before do
          @new_application = described_class.new(application_11).create_application
        end

        it 'should set as true' do
          applicants = @new_application.applicants
          expect(applicants.map(&:is_living_in_state)).to eq [true,true]
        end
      end

      context 'for out of state addresses for one of the dependents' do
        before do
          application_11.applicants.first.addresses.update_all(state: 'CA')
          @new_application = described_class.new(application_11).create_application
        end

        it 'should set as true' do
          applicants = @new_application.applicants
          expect(applicants.map(&:is_living_in_state)).to eq [false,true]
        end
      end

      context 'for no addresses for one of the dependents' do
        before do
          application_11.applicants.first.addresses.delete_all
          @new_application = described_class.new(application_11).create_application
        end

        it 'should set as true' do
          applicants = @new_application.applicants
          expect(applicants.map(&:is_living_in_state)).to eq [false,true]
        end
      end
    end
  end

  describe 'applicant with income, esi, non esi and mec evidences' do
    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:mec_check).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:esi_mec_determination).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_esi_mec_determination).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ifsv_determination).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:real_time_transfer).and_return(true)
      application.send(:create_evidences)
      @new_application = described_class.new(application).create_application
      @new_applicant = @new_application.applicants.first
    end

    it 'should not create evidences for new application' do
      expect(@new_applicant.income_evidence).to be_nil
      expect(@new_applicant.esi_evidence).to be_nil
      expect(@new_applicant.non_esi_evidence).to be_nil
      expect(@new_applicant.local_mec_evidence).to be_nil
    end

    it 'should create evidences when application is determined' do
      @new_application.applicants.each do |applicant|
        applicant.update_attributes(is_applying_coverage: true)
      end

      allow(@new_application).to receive(:is_application_valid?).and_return(true)
      @new_application.submit!
      @new_application.determine!
      applicant = @new_application.applicants.first
      expect(applicant.income_evidence).not_to be_nil
      expect(applicant.esi_evidence).not_to be_nil
      expect(applicant.non_esi_evidence).not_to be_nil
      expect(applicant.local_mec_evidence).not_to be_nil
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

  describe 'family with just two family members for create_application' do
    let!(:person) do
      per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 40.years)
      per.addresses.delete_all
      per
    end
    let!(:person2) do
      per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 30.years)
      person.ensure_relationship_with(per, 'spouse')
      per.addresses.delete_all
      person.save!
      per
    end
    let!(:family2) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
    let!(:family_member) { FactoryBot.create(:family_member, family: family2, person: person2) }
    let!(:application2) { FactoryBot.create(:financial_assistance_application, family_id: family2.id, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'submitted') }
    let!(:primary_applicant) do
      FactoryBot.create(:financial_assistance_applicant,
                        dob: person.dob,
                        first_name: person.first_name,
                        last_name: person.last_name,
                        gender: person.gender,
                        ssn: person.ssn,
                        citizen_status: person.citizen_status,
                        is_incarcerated: person.is_incarcerated,
                        indian_tribe_member: person.indian_tribe_member,
                        is_applying_coverage: true,
                        is_primary_applicant: true,
                        application: application2,
                        family_member_id: family2.family_members[0].id,
                        person_hbx_id: person.hbx_id)
    end
    let!(:spouse_applicant) do
      FactoryBot.create(:applicant,
                        application: application2,
                        is_applying_coverage: true,
                        first_name: person2.first_name,
                        last_name: person2.last_name,
                        gender: person2.gender,
                        ssn: person2.ssn,
                        dob: person2.dob,
                        citizen_status: person2.citizen_status,
                        is_incarcerated: person2.is_incarcerated,
                        indian_tribe_member: person2.indian_tribe_member,
                        is_primary_applicant: false,
                        family_member_id: family_member.id,
                        person_hbx_id: person2.hbx_id)
    end

    before do
      family.family_members.map(&:person).flatten.each do |p|
        p.addresses.delete_all
      end
      [application2].each do |applin|
        applin.applicants.first.update_attributes!(is_primary_applicant: true)
        address_attributes = {
          kind: 'home',
          address_1: '3 Awesome Street',
          address_2: '#300',
          city: FinancialAssistanceRegistry[:enroll_app].setting(:contact_center_city).item,
          state: FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
          zip: FinancialAssistanceRegistry[:enroll_app].setting(:contact_center_zip_code).item
        }
        if EnrollRegistry[:enroll_app].setting(:geographic_rating_area_model).item == 'county'
          address_attributes.merge!(
            county: FinancialAssistanceRegistry[:enroll_app].setting(:contact_center_county).item
          )
        end
        financial_assistance_address = ::FinancialAssistance::Locations::Address.new(address_attributes)
        applin.reload
        applin.applicants.each do |applicant|
          applicant.addresses << financial_assistance_address
          applicant.save!
        end
        family_id = applin.family_id
        family = Family.find(family_id) if family_id.present?
        family.family_members.each do |fm|
          main_app_address = Address.new(address_attributes)
          fm.person.addresses << main_app_address
          fm.person.save!
        end
      end

      family.reload
      application2.reload
    end

    context "when main app data is same as previous application data" do
      before do
        @new_application = described_class.new(application2).create_application
      end

      it 'should return application without any changes in data' do
        expect(@new_application.applicants[0].is_applying_coverage).to eq(application2.applicants[0].is_applying_coverage)
      end
    end

    context "when primary_member is non applicant" do
      it 'should return copied primary applicant as non applicant' do
        person.consumer_role.update_attributes(is_applying_coverage: false)
        @new_application = described_class.new(application2).create_application
        expect(@new_application.applicants[0].is_applying_coverage).not_to eq(application2.applicants[0].is_applying_coverage)
      end
    end

    context "when spouse_member is non applicant" do
      before do
        person2.consumer_role.update_attributes(is_applying_coverage: false)
        @new_application = described_class.new(application2).create_application
      end

      it 'should return copied spouse applicant as non applicant' do
        expect(@new_application.applicants[1].is_applying_coverage).not_to eq(application2.applicants[1].is_applying_coverage)
      end
    end

    context "when spouse_applicant is non applicant" do
      before do
        application2.applicants[1].update_attributes(is_applying_coverage: false)
        @new_application = described_class.new(application2).create_application
      end

      it 'should return copied spouse applicant as non applicant' do
        expect(@new_application.applicants[0].is_applying_coverage).to eq(application2.applicants[0].is_applying_coverage)
      end
    end
  end
end
