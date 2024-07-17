# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::AptcCsrCreditEligibilities::Renewals::Renew, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  before :all do
    DatabaseCleaner.clean
  end

  let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: '100095')}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:application) do
    FactoryBot.create(:financial_assistance_application,
                      hbx_id: '111000222',
                      family_id: family.id,
                      is_renewal_authorized: false,
                      is_requesting_voter_registration_application_in_mail: true,
                      years_to_renew: 5,
                      medicaid_terms: true,
                      report_change_terms: true,
                      medicaid_insurance_collection_terms: true,
                      parent_living_out_of_home_terms: true,
                      attestation_terms: true,
                      submission_terms: true,
                      assistance_year: TimeKeeper.date_of_record.year,
                      full_medicaid_determination: true)
  end

  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      person_hbx_id: '100095',
                      is_primary_applicant: true,
                      family_member_id: family.primary_applicant.id,
                      first_name: 'Gerald',
                      last_name: 'Rivers',
                      dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.beginning_of_month.day),
                      application: application)
  end

  let(:event) { Success(double) }
  let(:operation_instance) { described_class.new }

  before do
    allow(operation_instance.class).to receive(:new).and_return(operation_instance)
    allow(event.success).to receive(:publish).and_return(true)
    application.applicants.each do |appl|
      appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                         :address_1 => '1111 Awesome Street NE',
                                         :address_2 => '#111',
                                         :address_3 => '',
                                         :city => 'Washington',
                                         :country_name => '',
                                         :kind => 'home',
                                         :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                         :zip => '20001',
                                         :county => 'Cumberland')]
      appl.save!
    end
  end

  context 'success' do

    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(false)
    end

    context 'determined application with no years to renew' do
      before do
        application.update_attributes!({ aasm_state: 'determined', years_to_renew: [0, nil].sample })
        application.reload
        @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        @renewal_draft_app = @result.success
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end

      it 'should not return application' do
        expect(@renewal_draft_app).not_to be_a(::FinancialAssistance::Application)
      end

      let(:renewal_draft_blocker_reason) { 'years_to_renew is 0 or nil' }

      it 'returns application in income_verification_extension_required state' do
        expect(@result.failure).to match(renewal_draft_blocker_reason)
        expect(subject.renewal_application.income_verification_extension_required?).to be_truthy
      end
    end

    context '#full_medicaid_determination' do
      context 'when full_medicaid_determination feature is enabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:full_medicaid_determination_step).and_return(true)
          allow(FinancialAssistanceRegistry[:full_medicaid_determination_step].setting(:annual_eligibility_redetermination)).to receive(:item).and_return(true)

          application.update_attributes!({ aasm_state: 'determined', years_to_renew: 1 })
          application.reload
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
          @renewal_draft_app = @result.success
        end

        it 'should return application with full_medicaid_determination value' do
          expect(@renewal_draft_app.full_medicaid_determination).to eq true
        end
      end

      context 'when full_medicaid_determination feature is disabled' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:full_medicaid_determination_step).and_return(false)
          allow(FinancialAssistanceRegistry[:full_medicaid_determination_step].setting(:annual_eligibility_redetermination)).to receive(:item).and_return(false)

          application.update_attributes!({ aasm_state: 'determined', years_to_renew: 1 })
          application.reload
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
          @renewal_draft_app = @result.success
        end

        it 'should return application with nil full_medicaid_determination' do
          expect(@renewal_draft_app.full_medicaid_determination).to eq nil
        end
      end
    end

    context 'determined application for DC' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:full_medicaid_determination_step).and_return(true)
        allow(FinancialAssistanceRegistry[:full_medicaid_determination_step].setting(:annual_eligibility_redetermination)).to receive(:item).and_return(false)

        application.update_attributes!({ aasm_state: 'determined', years_to_renew: 1 })
        application.reload
        @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        @renewal_draft_app = @result.success
      end

      it 'should return success' do
        expect(@result).to be_success
      end

      it 'should return application' do
        expect(@renewal_draft_app).to be_a(::FinancialAssistance::Application)
      end

      it 'should return application with assistance_year' do
        expect(@renewal_draft_app.assistance_year).to eq(application.assistance_year.next)
      end

      # Verify if all the answers for questions on 'Your Preferences' & 'Submit Your Application' were copied
      context 'for attestations & other questions' do
        # Your Preferences:
        #   is_renewal_authorized
        #   is_requesting_voter_registration_application_in_mail
        #   years_to_renew
        context 'Your Preferences' do
          it 'should return application with is_renewal_authorized' do
            expect(@renewal_draft_app.is_renewal_authorized).to eq(application.is_renewal_authorized)
          end

          it 'should return application with is_requesting_voter_registration_application_in_mail' do
            expect(@renewal_draft_app.is_requesting_voter_registration_application_in_mail).to eq(application.is_requesting_voter_registration_application_in_mail)
          end

          it 'should return application with years_to_renew as zero' do
            expect(@renewal_draft_app.years_to_renew).to be_zero
          end
        end

        # Submit Your Application:
        #   medicaid_terms
        #   report_change_terms
        #   medicaid_insurance_collection_terms
        #   parent_living_out_of_home_terms
        #   attestation_terms
        #   submission_terms
        #   full_medicaid_determination
        context 'Submit Your Application' do
          it 'should return application with medicaid_terms' do
            expect(@renewal_draft_app.medicaid_terms).to eq(application.medicaid_terms)
          end

          it 'should return application with report_change_terms' do
            expect(@renewal_draft_app.report_change_terms).to eq(application.report_change_terms)
          end

          it 'should return application with medicaid_insurance_collection_terms' do
            expect(@renewal_draft_app.medicaid_insurance_collection_terms).to eq(application.medicaid_insurance_collection_terms)
          end

          it 'should return application with parent_living_out_of_home_terms' do
            expect(@renewal_draft_app.parent_living_out_of_home_terms).to eq(application.parent_living_out_of_home_terms)
          end

          it 'should return application with submission_terms' do
            expect(@renewal_draft_app.submission_terms).to eq(application.submission_terms)
          end

          it 'should return application with attestation_terms' do
            expect(@renewal_draft_app.attestation_terms).to eq(application.attestation_terms)
          end

          it 'should return application without full_medicaid_determination' do
            expect(@renewal_draft_app.full_medicaid_determination).to be nil
          end
        end
      end
    end

    context 'renewal_base_year' do
      before do
        years_to_renew = 4
        application.update_attributes!({ aasm_state: 'determined', years_to_renew: years_to_renew, renewal_base_year: TimeKeeper.date_of_record.year + years_to_renew, is_renewal_authorized: false })
        @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        @renewal_draft_app = @result.success
      end

      it 'should return renewal_base_year for renewal_draft_app same as input_application' do
        expect(@renewal_draft_app.renewal_base_year).to eq(application.renewal_base_year)
      end
    end
  end

  context 'failure' do

    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(false)
    end

    context 'submitted application' do
      before do
        application.update_attributes!(aasm_state: 'submitted')
        application.reload
        @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
      end

      it 'should return failure' do
        expect(@result).to be_failure
      end

      it 'should return application' do
        expect(@result.failure).to match(/Could not find any applications that are renewal eligible:/)
      end
    end

    context 'Renewal Application applicants update required' do
      let!(:person_11) { FactoryBot.create(:person, :with_consumer_role, first_name: 'Person_11')}
      let!(:person_12) do
        per = FactoryBot.create(:person, :with_consumer_role, first_name: 'Person_12')
        person_11.ensure_relationship_with(per, 'spouse')
        per
      end
      let!(:family_11) { FactoryBot.create(:family, :with_primary_family_member, person: person_11)}
      let!(:family_member_12) { FactoryBot.create(:family_member, person: person_12, family: family_11)}
      let!(:application_11) { FactoryBot.create(:financial_assistance_application, family_id: family_11.id, aasm_state: 'determined', hbx_id: "111000", effective_date: TimeKeeper.date_of_record, years_to_renew: 2) }
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

      context 'New Family member added without corresponding applicant' do
        let!(:person_13) do
          per = FactoryBot.create(:person, :with_consumer_role, first_name: 'Person_13')
          person_11.ensure_relationship_with(per, 'child')
          per
        end
        let!(:family_member_13) { FactoryBot.create(:family_member, person: person_13, family: family_11)}
        let(:renewal_draft_blocker_reason) { 'family_members_changed' }

        before do
          @result = subject.call({ family_id: application_11.family_id, renewal_year: application_11.assistance_year.next })
        end

        it 'should return failure and set renewal application state to applicants_update_required' do
          expect(@result.failure?).to eq true
          expect(subject.renewal_application.renewal_draft_blocker_reasons).to include(renewal_draft_blocker_reason)
          expect(subject.renewal_application.aasm_state).to eq 'applicants_update_required'
        end
      end

      context 'New Family member dropped with corresponding applicant' do
        before do
          family_11.remove_family_member(family_member_12.person)
          family_11.save!
          @result = subject.call({ family_id: application_11.family_id, renewal_year: application_11.assistance_year.next })
        end

        let(:renewal_draft_blocker_reason) { 'family_members_changed' }

        it 'should return failure and set renewal application state to applicants_update_required' do
          expect(@result.failure?).to eq true
          expect(subject.renewal_application.renewal_draft_blocker_reasons).to include(renewal_draft_blocker_reason)
          expect(subject.renewal_application.aasm_state).to eq 'applicants_update_required'
        end
      end

      context 'Family members changed and missing relationships' do
        before do
          allow(operation_instance).to receive(:missing_relationships?).and_return(true)
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        end

        let(:renewal_draft_blocker_reason) { 'missing_relationships' }

        it 'should return failure' do
          expect(@result).to be_failure
          expect(subject.renewal_application.aasm_state).to eq 'applicants_update_required'
          expect(subject.renewal_application.renewal_draft_blocker_reasons).to include(renewal_draft_blocker_reason)
          expect(@result.failure).to match(renewal_draft_blocker_reason)
        end
      end

      context "Invalid relationships between applicants" do
        before do
          application_11.ensure_relationship_with_primary(applicant_12, 'life_partner')
          person_11.ensure_relationship_with(person_12, 'life_partner')
          @result = subject.call({ family_id: application_11.family_id, renewal_year: application_11.assistance_year.next })
        end

        let(:renewal_draft_blocker_reason) { 'invalid_relationships' }

        it 'should return failure' do
          expect(@result).to be_failure
          expect(subject.renewal_application.aasm_state).to eq 'applicants_update_required'
          expect(subject.renewal_application.renewal_draft_blocker_reasons).to include(renewal_draft_blocker_reason)
          expect(@result.failure).to match(renewal_draft_blocker_reason)
        end
      end
    end

    context 'missing keys' do
      context 'missing family_id' do
        before do
          @result = subject.call({ renewal_year: TimeKeeper.date_of_record.year })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Missing family_id key')
        end
      end

      context 'missing renewal_year' do
        before do
          @result = subject.call({ family_id: BSON::ObjectId.new })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Missing renewal_year key')
        end
      end
    end

    context 'missing values or invalid values' do
      context 'missing value for family_id' do
        before do
          @result = subject.call({ family_id: nil, renewal_year: TimeKeeper.date_of_record.year })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Cannot find family with input value:  for key family_id")
        end
      end

      context 'missing value for renewal_year' do
        before do
          @result = subject.call({ family_id: family.id, renewal_year: nil })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq('Invalid value:  for key renewal_year, must be an Integer')
        end
      end

      context 'invalid value for family_id' do
        before do
          @result = subject.call({ family_id: 'test', renewal_year: TimeKeeper.date_of_record.year })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to match('Cannot find family with input value: test for key family_id')
        end
      end

      context 'invalid value for renewal_year' do
        before do
          @result = subject.call({ family_id: family.id, renewal_year: TimeKeeper.date_of_record.year.to_s })
        end

        it 'should return failure with error message' do
          expect(@result.failure).to match(/for key renewal_year, must be an Integer/)
        end
      end
    end

    context 'no applications for given inputs' do
      let(:validated_params) { { family_id: family.id, renewal_year: TimeKeeper.date_of_record.year } }
      before do
        ::FinancialAssistance::Application.destroy_all
        @result = subject.call(validated_params)
      end

      it 'should return failure with error message' do
        expect(@result.failure).to eq("Could not find any applications that are renewal eligible: #{validated_params}.")
      end
    end

    context 'for an application which is not in determined state' do
      shared_examples_for 'non determined state application' do |app_state|

        let(:validated_params) { { family_id: application.family_id, renewal_year: application.assistance_year.next } }
        before do
          application.update_attributes!(aasm_state: app_state)
          @result = subject.call(validated_params)
        end

        it 'should return failure' do
          expect(@result).to be_failure
        end

        it "should return failure with error message for application with aasm_state: #{app_state}" do
          expect(@result.failure).to eq("Could not find any applications that are renewal eligible: #{validated_params}.")
        end
      end

      context 'failure because of application aasm_state' do
        it_behaves_like 'non determined state application', 'draft'
        it_behaves_like 'non determined state application', 'renewal_draft'
        it_behaves_like 'non determined state application', 'determination_response_error'
      end
    end
  end

  describe 'application renewal determination eligibility' do
    let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: '100095')}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:application) do
      FactoryBot.create(:financial_assistance_application,
                        hbx_id: '111000222',
                        family_id: family.id,
                        is_renewal_authorized: false,
                        is_requesting_voter_registration_application_in_mail: true,
                        years_to_renew: 5,
                        medicaid_terms: true,
                        report_change_terms: true,
                        medicaid_insurance_collection_terms: true,
                        parent_living_out_of_home_terms: true,
                        attestation_terms: true,
                        submission_terms: true,
                        assistance_year: TimeKeeper.date_of_record.year,
                        full_medicaid_determination: true)
    end

    let!(:applicant_1) do
      FactoryBot.create(:financial_assistance_applicant,
                        person_hbx_id: '100095',
                        is_primary_applicant: true,
                        family_member_id: family.primary_applicant.id,
                        first_name: 'Gerald',
                        last_name: 'Rivers',
                        dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.beginning_of_month.day),
                        application: application)
    end

    let!(:applicant_2) do
      FactoryBot.create(:financial_assistance_applicant,
                        person_hbx_id: '100096',
                        is_primary_applicant: true,
                        family_member_id: family.primary_applicant.id,
                        first_name: 'Diana',
                        last_name: 'Rivers',
                        dob: Date.new(Date.today.year - 22, Date.today.month, Date.today.beginning_of_month.day),
                        application: application)
    end

    let(:event) { Success(double) }
    let(:operation_instance) { described_class.new }

    before do
      allow(operation_instance.class).to receive(:new).and_return(operation_instance)
      allow(event.success).to receive(:publish).and_return(true)
      application.applicants.each do |appl|
        appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                           :address_1 => '1111 Awesome Street NE',
                                           :address_2 => '#111',
                                           :address_3 => '',
                                           :city => 'Washington',
                                           :country_name => '',
                                           :kind => 'home',
                                           :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                           :zip => '20001',
                                           :county => 'Cumberland')]
        appl.save!
      end
    end

    context 'skip_eligibility_redetermination Feature' do
      context 'application has all ineligible applicants and skip_eligibility_redetermination flag is set to true' do
        before do
          application.applicants.each do |appl|
            appl.update_attributes!(is_totally_ineligible: true)
          end
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(true)
          @input_params = { family_id: application.family_id, renewal_year: application.assistance_year.next }
          @result = subject.call(@input_params)
        end

        it 'should return failure' do
          expect(@result).to be_failure
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Could not find any applications that are renewal eligible: #{@input_params}.")
        end
      end

      context 'application has all not applyling coverage applicants and skip_eligibility_redetermination flag is set to true' do
        before do
          application.applicants.each do |appl|
            appl.update_attributes!(is_applying_coverage: false)
          end
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(true)
          @input_params = { family_id: application.family_id, renewal_year: application.assistance_year.next }
          @result = subject.call(@input_params)
        end

        it 'should return failure' do
          expect(@result).to be_failure
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Could not find any applications that are renewal eligible: #{@input_params}.")
        end
      end

      context 'application has all medicaid chip applicants and skip_eligibility_redetermination flag is set to true' do
        before do
          application.applicants.each do |appl|
            appl.update_attributes!(is_medicaid_chip_eligible: true)
          end
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(true)
          @input_params = { family_id: application.family_id, renewal_year: application.assistance_year.next }
          @result = subject.call(@input_params)
        end

        it 'should return failure' do
          expect(@result).to be_failure
        end

        it 'should return failure with error message' do
          expect(@result.failure).to eq("Could not find any applications that are renewal eligible: #{@input_params}.")
        end
      end

      context 'application has one medicaid chip and uqhp eligible applicant and skip_eligibility_redetermination flag is set to true' do
        before do
          application.applicants[0].update_attributes!(is_medicaid_chip_eligible: true)
          application.applicants[1].update_attributes!(is_without_assistance: true)
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(true)
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        end

        it 'should return success' do
          expect(@result).to be_success
        end
      end

      context 'application has one medicaid chip and one insurance assistance eligible applicant and skip_eligibility_redetermination flag is set to true' do
        before do
          application.applicants[0].update_attributes!(is_medicaid_chip_eligible: true)
          application.applicants[1].update_attributes!(is_ia_eligible: true)
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(true)
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        end

        it 'should return success' do
          expect(@result).to be_success
        end
      end

      context 'skip eligibility redetermination feature flag is set to false' do
        before do
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(false)
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        end

        it 'should return success' do
          expect(@result).to be_success
        end
      end

      context 'application has all ineligible applicants and skip_eligibility_redetermination flag is set to false' do
        before do
          application.applicants.each do |appl|
            appl.update_attributes!(is_totally_ineligible: true)
          end
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(false)
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
          @renewal_draft_app = @result.success
        end

        it 'should return success' do
          expect(@result).to be_success
        end

        it 'should return application' do
          expect(@renewal_draft_app).to be_a(::FinancialAssistance::Application)
        end

        it 'should return application with assistance_year' do
          expect(@renewal_draft_app.assistance_year).to eq(application.assistance_year.next)
        end
      end

      context 'application has all not applying coverage applicants and skip_eligibility_redetermination flag is set to false' do
        before do
          application.applicants.each do |appl|
            appl.update_attributes!(is_applying_coverage: false)
          end
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(false)
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        end

        it 'should return success' do
          expect(@result).to be_success
        end
      end

      context 'application has all medicaid chip applicants and skip_eligibility_redetermination flag is set to false' do
        before do
          application.applicants.each do |appl|
            appl.update_attributes!(is_medicaid_chip_eligible: true)
          end
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(false)
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        end

        it 'should return success' do
          expect(@result).to be_success
        end
      end

      context 'application has one medicaid chip and uqhp eligible applicant and skip_eligibility_redetermination flag is set to false' do
        before do
          application.applicants[0].update_attributes!(is_medicaid_chip_eligible: true)
          application.applicants[1].update_attributes!(is_without_assistance: true)
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(false)
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
          @renewal_draft_app = @result.success
        end

        it 'should return success' do
          expect(@result).to be_success
        end
      end

      context 'application has one medicaid chip and one insurance assistance eligible applicant and skip_eligibility_redetermination flag is set to false' do
        before do
          application.applicants[0].update_attributes!(is_medicaid_chip_eligible: true)
          application.applicants[1].update_attributes!(is_ia_eligible: true)
          allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:skip_eligibility_redetermination).and_return(false)
          @result = subject.call({ family_id: application.family_id, renewal_year: application.assistance_year.next })
        end

        it 'should return success' do
          expect(@result).to be_success
        end
      end
    end
  end
end
