# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'

RSpec.describe ::FinancialAssistance::Application, type: :model, dbclean: :after_each do
  include Dry::Monads[:result, :do]

  let(:family_id) { BSON::ObjectId.new }
  let!(:year) { TimeKeeper.date_of_record.year }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id) }
  let!(:eligibility_determination1) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:eligibility_determination2) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:eligibility_determination3) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:application2) { FactoryBot.create(:financial_assistance_application, family_id: family_id, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'denied') }
  let!(:application3) { FactoryBot.create(:financial_assistance_application, family_id: family_id, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'determination_response_error') }
  let!(:application4) { FactoryBot.create(:financial_assistance_application, family_id: family_id, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'determined') }
  let!(:application5) { FactoryBot.create(:financial_assistance_application, family_id: family_id, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'determined') }
  let!(:applicant1) { FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: eligibility_determination1.id, application: application, family_member_id: BSON::ObjectId.new) }
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: eligibility_determination2.id, application: application, family_member_id: BSON::ObjectId.new) }
  let!(:applicant3) { FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: eligibility_determination3.id, application: application, family_member_id: BSON::ObjectId.new) }

  let(:create_instate_addresses) do
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
                                         county: '')]
      appl.save!
    end
    application.save!
  end

  let(:create_relationships) do
    application.applicants.first.update_attributes!(is_primary_applicant: true) unless application.primary_applicant.present?
    application.ensure_relationship_with_primary(applicant2, 'spouse')
    application.ensure_relationship_with_primary(applicant3, 'child')
    application.add_or_update_relationships(applicant2, applicant3, 'parent')
    application.build_relationship_matrix
    application.save!
  end

  describe '.modelFeilds' do
    it { is_expected.to have_field(:hbx_id).of_type(String) }
    it { is_expected.to have_field(:external_id).of_type(String) }
    it { is_expected.to have_field(:integrated_case_id).of_type(String) }
    it { is_expected.to have_field(:haven_app_id).of_type(String) }
    it { is_expected.to have_field(:haven_ic_id).of_type(String) }
    it { is_expected.to have_field(:e_case_id).of_type(String) }
    it { is_expected.to have_field(:applicant_kind).of_type(String) }
    it { is_expected.to have_field(:request_kind).of_type(String) }
    it { is_expected.to have_field(:motivation_kind).of_type(String) }
    it { is_expected.to have_field(:is_joint_tax_filing).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:eligibility_determination_id).of_type(BSON::ObjectId) }
    it { is_expected.to have_field(:aasm_state).of_type(String).with_default_value_of(:draft) }
    it { is_expected.to have_field(:submitted_at).of_type(DateTime) }
    it { is_expected.to have_field(:effective_date).of_type(DateTime) }
    it { is_expected.to have_field(:timeout_response_last_submitted_at).of_type(DateTime) }
    it { is_expected.to have_field(:assistance_year).of_type(Integer) }
    it { is_expected.to have_field(:is_renewal_authorized).of_type(Mongoid::Boolean).with_default_value_of(true) }
    it { is_expected.to have_field(:renewal_base_year).of_type(Integer) }
    it { is_expected.to have_field(:years_to_renew).of_type(Integer) }
    it { is_expected.to have_field(:is_requesting_voter_registration_application_in_mail).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:us_state).of_type(String) }
    it { is_expected.to have_field(:medicaid_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:medicaid_insurance_collection_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:report_change_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:parent_living_out_of_home_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:attestation_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:submission_terms).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:request_full_determination).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_ridp_verified).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:determination_http_status_code).of_type(Integer) }
    it { is_expected.to have_field(:determination_error_message).of_type(String) }
    it { is_expected.to have_field(:has_eligibility_response).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:workflow).of_type(Hash).with_default_value_of({}) }
  end

  describe '.Validations' do
    subject { application }

    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'is not valid without a hbx_id' do
      subject.hbx_id = nil
      expect(subject).to_not be_valid(:submission)
    end

    it 'is not valid without an applicant_kind' do
      subject.applicant_kind = nil
      expect(subject).to_not be_valid(:submission)
    end
  end

  describe '.Associations' do
    it 'embeds many applicants' do
      assc = described_class.reflect_on_association(:applicants)
      expect(assc.class).to eq Mongoid::Association::Embedded::EmbedsMany
    end

    it 'embeds many workflow_state_transitions' do
      assc = described_class.reflect_on_association(:workflow_state_transitions)
      expect(assc.class).to eq Mongoid::Association::Embedded::EmbedsMany
    end
  end

  describe '.Constants' do
    let(:class_constants)  { subject.class.constants }

    it 'should have years to renew range constant' do
      expect(class_constants.include?(:YEARS_TO_RENEW_RANGE)).to be_truthy
      expect(described_class::YEARS_TO_RENEW_RANGE).to eq(0..5)
    end

    it 'should have renewal basse year range constant' do
      expect(class_constants.include?(:RENEWAL_BASE_YEAR_RANGE)).to be_truthy
      # Open Enrollment case where user can submit application for next_year and can authorize
      # renewal for next 5 years which can be current_year + 6 years.
      expect(described_class::RENEWAL_BASE_YEAR_RANGE).to eq(2013..TimeKeeper.date_of_record.year + 6)
    end

    it 'should have applicant kinds constant' do
      expect(class_constants.include?(:APPLICANT_KINDS)).to be_truthy
      expect(described_class::APPLICANT_KINDS).to eq(['user and/or family', 'call center rep or case worker', 'authorized representative'])
    end

    it 'should have source kinds constant' do
      expect(class_constants.include?(:SOURCE_KINDS)).to be_truthy
      expect(described_class::SOURCE_KINDS).to eq(%w[paper source in-person])
    end

    it 'should have request kinds constant' do
      expect(class_constants.include?(:REQUEST_KINDS)).to be_truthy
      expect(described_class::REQUEST_KINDS).to eq(%w[])
    end

    it 'should have motivation kinds constant' do
      expect(class_constants.include?(:MOTIVATION_KINDS)).to be_truthy
      expect(described_class::MOTIVATION_KINDS).to eq(%w[insurance_affordability])
    end

    it 'should have submitted status constant' do
      expect(class_constants.include?(:SUBMITTED_STATUS)).to be_truthy
      expect(described_class::SUBMITTED_STATUS).to eq(%w[submitted verifying_income])
    end

    it 'should have RENEWAL_ELIGIBLE_STATES constant' do
      expect(class_constants.include?(:RENEWAL_ELIGIBLE_STATES)).to be_truthy
      expect(described_class::RENEWAL_ELIGIBLE_STATES).to eq(%w[submitted determined imported])
    end
  end

  describe '.Scopes' do
    it 'should not return draft applications' do
      expect(FinancialAssistance::Application.all.for_verifications.map(&:aasm_state)).not_to include 'draft'
      expect(FinancialAssistance::Application.all.for_verifications.map(&:aasm_state)).to include 'determined'
    end
  end

  describe '.compute_actual_days_worked' do
    it 'returns actual working days between start_date and end_date' do
      start_date = Date.new(year, 2, 14)
      end_date = Date.new(year, 9, 23)
      expect(application.compute_actual_days_worked(year, start_date, end_date)).to eq 158
    end
  end

  describe '.has_accepted_medicaid_terms?' do
    it 'returns true if includes SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'submitted')
      application.send(:has_accepted_medicaid_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(true)
    end
    it 'returns false if do not include SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'determined')
      application.send(:has_accepted_medicaid_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(false)
    end
  end

  describe '.has_accepted_attestation_terms?' do
    it 'returns true if includes SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'submitted')
      application.send(:has_accepted_attestation_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(true)
    end
    it 'returns false if do not include SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'determined')
      application.send(:has_accepted_attestation_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(false)
    end
  end

  describe '.has_accepted_submission_terms?' do
    it 'returns true if includes SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'submitted')
      application.send(:has_accepted_submission_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(true)
    end
    it 'returns false if do not include SUBMITTED_STATUS' do
      application.update_attributes(aasm_state: 'determined')
      application.send(:has_accepted_submission_terms?)
      expect(described_class::SUBMITTED_STATUS.include?(application.aasm_state)).to eq(false)
    end
  end

  describe '.primary_applicant' do
    it 'returns primary_applicant' do
      primary_applicant = application.active_applicants.detect(&:is_primary_applicant?)
      expect(application.primary_applicant).to eq(primary_applicant)
    end
  end

  describe '.current_csr_percent_as_integer' do
    it 'should return current csr percent' do
      application.eligibility_determination_for(eligibility_determination1.id)
      expect(application.current_csr_percent_as_integer(eligibility_determination1.id)).to eq(eligibility_determination1.csr_percent_as_integer)
    end

    it 'should return right eligibility_determination' do
      ed = application.eligibility_determinations[0]
      expect(ed).to eq eligibility_determination1
    end
  end

  describe '.complete?' do
    it 'should returns true if application is valid and complete' do
      allow(application).to receive(:is_application_valid?).and_return(true)
      expect(application.complete?).to be_truthy
    end
    it 'should returns false if application is not valid' do
      allow(application).to receive(:is_application_valid?).and_return(false)
      expect(application.complete?).to be_falsey
    end
  end

  describe '.is_submitted?' do
    it 'should returns true if aasm state is submitted' do
      application.update_attributes(aasm_state: 'submitted')
      expect(application.is_submitted?).to be_truthy
    end

    it 'should returns aasm state as submitted' do
      application.update_attributes(aasm_state: 'submitted')
      expect(application.aasm_state).to include('submitted')
    end

    it 'should return false if aasm state is not submitted' do
      expect(application.is_submitted?).to be_falsey
    end

    it 'should not return aasm state as submitted' do
      expect(application.aasm_state).not_to include('submitted')
    end
  end

  describe '.ready_for_attestation?' do
    let!(:valid_application) do
      FactoryBot.create(
        :financial_assistance_application,
        family_id: BSON::ObjectId.new,
        hbx_id: '345332',
        applicant_kind: 'user and/or family',
        request_kind: 'request-kind',
        motivation_kind: 'motivation-kind',
        us_state: 'DC',
        is_ridp_verified: true,
        assistance_year: TimeKeeper.date_of_record.year,
        aasm_state: 'draft',
        medicaid_terms: true,
        attestation_terms: true,
        submission_terms: true,
        medicaid_insurance_collection_terms: true,
        report_change_terms: true,
        parent_living_out_of_home_terms: true,
        applicants: [applicant_primary]
      )
    end
    let!(:applicant_primary) do
      FactoryBot.create(:applicant, eligibility_determination_id: eligibility_determination1.id, application: application, family_member_id: family_member_id)
    end
    let(:family_member_id) { BSON::ObjectId.new }

    it 'should returns true if application is ready_for_attestation' do
      allow(applicant_primary).to receive(:applicant_validation_complete?).and_return(true)
      allow(valid_application).to receive(:relationships_complete?).and_return(true)
      expect(valid_application.ready_for_attestation?).to be_truthy
    end

    it 'should returns false if application is not ready_for_attestation' do
      expect(valid_application.ready_for_attestation?).to be_falsey
    end
  end

  describe '.incomplete_applicants?' do
    it 'should returns true if application has incomplete_applicants' do
      allow(applicant1).to receive(:applicant_validation_complete?).and_return(false)
      application.incomplete_applicants?
      expect(application.incomplete_applicants?).to be_truthy
    end

    it 'should returns false if application has no incomplete_applicants' do
      expect(application.ready_for_attestation?).to be_falsey
    end
  end

  describe '.next_incomplete_applicant' do
    it 'returns applicant primary if application has next_incomplete_applicant' do
      allow(applicant1).to receive(:applicant_validation_complete?).and_return(false)
      expect(application.next_incomplete_applicant).to eq applicant1
    end
  end

  describe '.active_applicants' do
    it 'returns active_applicants for a given application' do
      expect(application.active_applicants).to eq application.applicants.where(:is_active => true)
    end
  end

  describe '.is_draft?' do
    it 'should returns true if aasm state is draft' do
      application.update_attributes(aasm_state: 'draft')
      expect(application.is_draft?).to be_truthy
    end

    it 'should returns aasm state draft' do
      application.update_attributes(aasm_state: 'draft')
      expect(application.aasm_state).to include('draft')
    end

    it 'should return false if aasm state is not draft' do
      application.update_attributes(aasm_state: 'determined')
      expect(application.is_draft?).to be_falsey
    end

    it 'should not return aasm state as draft' do
      application.update_attributes(aasm_state: 'determined')
      expect(application.aasm_state).not_to include('draft')
    end
  end

  describe '.is_determined?' do
    it 'should returns true if aasm state is determined' do
      application.update_attributes(aasm_state: 'determined')
      expect(application.is_determined?).to be_truthy
    end

    it 'should returns aasm state as determined' do
      application.update_attributes(aasm_state: 'determined')
      expect(application.aasm_state).to include('determined')
    end

    it 'should return false if aasm state is not determined' do
      application.update_attributes(aasm_state: 'draft')
      expect(application.is_determined?).to be_falsey
    end

    it 'should not return aasm state as determined' do
      application.update_attributes(aasm_state: 'draft')
      expect(application.aasm_state).not_to include('determined')
    end
  end

  describe '.set_assistance_year' do
    let(:family_id)       { BSON::ObjectId.new }
    let(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id) }
    it 'updates assistance year' do
      application.update_attributes!(assistance_year: nil)
      application.send(:set_assistance_year)
      expect(application.assistance_year).to eq(FinancialAssistanceRegistry[:enrollment_dates].settings(:application_year).item.constantize.new.call.value!)
    end

    context 'for existing assistance_year' do
      before do
        application.update_attributes!(assistance_year: (TimeKeeper.date_of_record.year + 3))
        application.send(:set_assistance_year)
      end

      it 'should not update assistance year' do
        expect(application.assistance_year).not_to eq(FinancialAssistanceRegistry[:enrollment_dates].settings(:application_year).item.constantize.new.call.value!)
        expect(application.assistance_year).to eq(TimeKeeper.date_of_record.year + 3)
      end
    end
  end

  describe '.set_effective_date' do
    let(:family_id) { BSON::ObjectId.new }
    let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id) }

    context 'for non existing effective_date' do
      before do
        application.send(:set_effective_date)
      end

      it 'should update effective_date' do
        expect(application.effective_date).to eq(FinancialAssistanceRegistry[:enrollment_dates].settings(:earliest_effective_date).item.constantize.new.call.value!)
      end
    end

    context 'for existing effective_date' do
      before do
        application.update_attributes!(effective_date: Date.new(TimeKeeper.date_of_record.year + 3))
        application.send(:set_effective_date)
      end

      it 'should not update effective_date' do
        expect(application.effective_date).not_to eq(FinancialAssistanceRegistry[:enrollment_dates].settings(:earliest_effective_date).item.constantize.new.call.value!)
        expect(application.effective_date).to eq(Date.new(TimeKeeper.date_of_record.year + 3))
      end
    end
  end

  describe '.eligibility_determinations' do
    it 'verifies eligibility_determinations count of a given applicant' do
      expect(application.eligibility_determinations.count).to eq 3
    end
  end

  describe 'trigger eligibility notice' do
    let!(:applicant) { FactoryBot.create(:applicant, eligibility_determination_id: eligibility_determination1.id, application: application, family_member_id: BSON::ObjectId.new) }
    before do
      application.update_attributes(:aasm_state => 'submitted')
    end

    it 'on event determine and family totally eligibile' do
      expect(application.is_family_totally_ineligibile).to be_falsey
      application.determine!
    end
  end

  describe 'trigger ineligibilility notice' do
    let(:family_member_id) { BSON::ObjectId.new }
    let!(:applicant) { FactoryBot.create(:applicant, eligibility_determination_id: eligibility_determination1.id, application: application, family_member_id: family_member_id) }
    before do
      application.active_applicants.each do |applicant|
        applicant.is_totally_ineligible = true
        applicant.save!
      end
      application.update_attributes(:aasm_state => 'submitted')
    end

    it 'event determine and family totally ineligibile' do
      expect(application.is_family_totally_ineligibile).to be_truthy
      application.determine!
    end
  end

  describe 'generates hbx_id for application' do
    let(:new_family_id) { BSON::ObjectId.new }
    let(:new_application) { FactoryBot.build(:financial_assistance_application, family_id: new_family_id) }

    it 'creates an hbx id if do not exists' do
      expect(new_application.hbx_id).to eq nil
      new_application.save
      expect(new_application.hbx_id).not_to eq nil
    end
  end

  describe 'for create_eligibility_determinations' do
    before :each do
      application.update_attributes(family_id: family_id, hbx_id: '345334', applicant_kind: 'user and/or family', request_kind: 'request-kind',
                                    motivation_kind: 'motivation-kind', us_state: 'DC', is_ridp_verified: true, assistance_year: TimeKeeper.date_of_record.year, aasm_state: 'draft',
                                    medicaid_terms: true, attestation_terms: true, submission_terms: true, medicaid_insurance_collection_terms: true,
                                    report_change_terms: true, parent_living_out_of_home_terms: true)
      allow(application).to receive(:is_application_valid?).and_return(true)
    end

    it 'When there are two joint filers and one claimed as tax dependent - applicants looping order 1' do
      applicant1.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: true, is_required_to_file_taxes: true)
      applicant2.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant1.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant3.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: true, is_required_to_file_taxes: true)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq 'tax_filer'
      expect(applicant2.tax_filer_kind).to eq 'dependent'
      expect(applicant3.tax_filer_kind).to eq 'tax_filer'
    end

    it 'When there is one tax filers and two claimed as tax dependent - applicants looping order 2' do
      applicant1.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant3.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant2.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant3.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant3.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq 'dependent'
      expect(applicant2.tax_filer_kind).to eq 'dependent'
      expect(applicant3.tax_filer_kind).to eq 'tax_filer'
    end

    it 'When there is one tax filers and two claimed as tax dependent - applicants looping order 3' do
      applicant1.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      applicant2.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant1.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      applicant3.update_attributes(is_claimed_as_tax_dependent: false, claimed_as_tax_dependent_by: nil, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq 'tax_filer'
      expect(applicant2.tax_filer_kind).to eq 'dependent'
      expect(applicant3.tax_filer_kind).to eq 'non_filer'
    end

    it 'When there are two tax filers and one claimed as tax dependent - applicants looping order 4' do
      applicant1.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      applicant2.update_attributes(is_claimed_as_tax_dependent: false, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: true)
      applicant3.update_attributes(is_claimed_as_tax_dependent: true, claimed_as_tax_dependent_by: applicant1.id, tax_filer_kind: nil, is_joint_tax_filing: false, is_required_to_file_taxes: false)
      application.submit!
      expect(applicant1.tax_filer_kind).to eq 'tax_filer'
      expect(applicant2.tax_filer_kind).to eq 'tax_filer'
      expect(applicant3.tax_filer_kind).to eq 'dependent'
    end
  end

  describe 'applications with eligibility determinations, tax households and applicants' do
    it 'should return all the eligibility determinations of the application' do
      application.update_attributes(assistance_year: year)
      expect(application.eligibility_determinations_for_year(year).size).to eq 3
      application.eligibility_determinations_for_year(year).each do |ed|
        expect(application.eligibility_determinations_for_year(year)).to include(ed)
      end
    end

    it 'should return all the eligibility determinations of the application' do
      expect(application.eligibility_determinations.count).to eq 3
      expect(application.eligibility_determinations).to eq [eligibility_determination1, eligibility_determination2, eligibility_determination3]
    end

    it 'should not return wrong number of eligibility determinations of the application' do
      expect(application.eligibility_determinations.count).not_to eq 4
      expect(application.eligibility_determinations).not_to eq [eligibility_determination1, eligibility_determination2]
    end

    it 'should return the latest eligibility determinations' do
      eligibility_determination1.update_attributes('effective_starting_on' => Date.new(year,1,1), is_eligibility_determined: true)
      eligibility_determination2.update_attributes('effective_starting_on' => Date.new(year,1,1), is_eligibility_determined: true)
      expect(application.latest_active_eligibility_determinations_with_year(year).count).to eq 2
      expect(application.latest_active_eligibility_determinations_with_year(year)).to eq [eligibility_determination1, eligibility_determination2]
    end

    it 'should only return latest eligibility_determinations of application' do
      expect(application.latest_active_eligibility_determinations_with_year(year).count).not_to eq 3
      expect(application.latest_active_eligibility_determinations_with_year(year)).not_to eq [eligibility_determination1, eligibility_determination2, eligibility_determination3]
    end

    it 'should match correct eligibility' do
      expect(application.eligibility_determinations[0]).to eq eligibility_determination1
      expect(application.eligibility_determinations[1]).to eq eligibility_determination2
      expect(application.eligibility_determinations[2]).to eq eligibility_determination3
    end

    it 'should not return wrong eligibility determinations' do
      application.update_attributes(assistance_year: year)
      expect(application.eligibility_determinations_for_year(year).size).not_to eq 1
      ed1 = application.eligibility_determinations[0]
      expect(ed1).not_to eq eligibility_determination3
    end

    it 'should return unique eligibility determinations with active_approved_application applicants' do
      expect(application.eligibility_determinations.count).to eq 3
      expect(application.eligibility_determinations).to eq [eligibility_determination1, eligibility_determination2, eligibility_determination3]
    end

    it 'should not return all eligibility_determinations' do
      expect(application.eligibility_determinations).not_to eq applicant1.eligibility_determination.to_a
    end
  end

  context 'is_reviewable?' do
    let(:faa) { double(:application) }
    context 'when submitted' do
      it 'should return true' do
        allow(application).to receive(:aasm_state).and_return('submitted')
        expect(application.is_reviewable?).to eq true
      end
    end

    context 'when determination_response_error' do
      it 'should return true' do
        allow(application).to receive(:aasm_state).and_return('determination_response_error')
        expect(application.is_reviewable?).to eq true
      end
    end

    context 'when determined' do
      it 'should return true' do
        allow(application).to receive(:aasm_state).and_return('determined')
        expect(application.is_reviewable?).to eq true
      end
    end

    it 'should return false if the application is in draft state' do
      allow(application).to receive(:aasm_state).and_return('draft')
      expect(application.is_reviewable?).to eq false
    end
  end

  describe 'check the validity of an application' do

    let!(:valid_app) { FactoryBot.create(:financial_assistance_application, aasm_state: 'draft', family_id: family_id) }
    let!(:invalid_app) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: 'draft') }
    let!(:applicant_primary) { FactoryBot.create(:applicant, eligibility_determination_id: ed1.id, is_primary_applicant: true, application: valid_app) }
    let!(:applicant_primary2) { FactoryBot.create(:applicant, eligibility_determination_id: ed2.id, is_primary_applicant: true, application: invalid_app) }
    let!(:ed1) { FactoryBot.create(:financial_assistance_eligibility_determination, application: valid_app) }
    let!(:ed2) { FactoryBot.create(:financial_assistance_eligibility_determination, application: invalid_app) }

    before do
      allow(valid_app).to receive(:trigger_fdhs_calls).and_return(true)
    end

    it 'should allow a sucessful state transition for valid application' do
      allow(valid_app).to receive(:is_application_valid?).and_return(true)
      expect(valid_app.submit).to be_truthy
      expect(valid_app.determine).to be_truthy
      expect(valid_app.aasm_state).to eq 'determined'
    end

    it 'should prevent state transition for invalid application' do
      invalid_app.update_attributes!(hbx_id: nil)
      expect(invalid_app).to receive(:report_invalid)
      invalid_app.submit!
      expect(invalid_app.aasm_state).to eq 'draft'
    end

    it 'should invoke submit_application on a submit of an valid application' do
      allow(valid_app).to receive(:is_application_valid?).and_return(true)
      valid_app.submit!
    end

    it 'should not invoke submit_application for invalid application' do
      invalid_app.submit!
    end

    it 'should record transition on a valid application submit' do
      expect(valid_app).to receive(:record_transition)
      valid_app.submit!
    end

    it 'should record transition on an invalid application submit' do
      expect(invalid_app).to receive(:record_transition)
      invalid_app.submit!
    end

    it 'should not create verification documents for schema invalid application' do
      invalid_app.update_attributes!(hbx_id: nil)
      expect(invalid_app).to receive(:report_invalid)
      invalid_app.submit!
      expect(invalid_app.aasm_state).to eq 'draft'
      expect(applicant_primary2.verification_types.count).to eq 0
    end
  end

  describe '.create_evidences' do

    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:mec_check).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:esi_mec_determination).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_esi_mec_determination).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ifsv_determination).and_return(true)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:verification_type_income_verification).and_return(true)
      allow(applicant1).to receive(:is_ia_eligible?).and_return(true)
    end

    it 'should create MEC evidences, ACES MEC check only if is_ia_eligible? not true' do
      application.send(:create_evidences)
      expect(applicant1.evidences.count).to eq 4
      expect(applicant2.evidences.count).to eq 4
    end

    it 'should have both income and mec in pending state' do
      application.active_applicants.each do |applicant|
        applicant.evidences.each do |type|
          expect(type.eligibility_status).to eq('attested')
        end
      end
    end
  end

  describe '.delete_verification_documents' do

    before do
      application.send(:create_verification_documents)
    end

    xit 'should delete income and mec verification types' do
      expect(applicant1.verification_types.count).to eq 2
      application.send(:delete_verification_documents)
      application.active_applicants.each do |applicant|
        expect(applicant.verification_types.count).to eq 0
      end
    end
  end

  context 'add_eligibility_determination' do
    let(:xml) { File.read(::FinancialAssistance::Engine.root.join('spec', 'test_data', 'haven_eligibility_response_payloads', 'verified_1_member_family.xml')) }
    let(:message) do
      {determination_http_status_code: 200, has_eligibility_response: true,
       haven_app_id: '1234', haven_ic_id: '124', eligibility_response_payload: xml}
    end
    let!(:person10) do
      FactoryBot.create(:person, :with_consumer_role, hbx_id: '20944967', last_name: 'Test', first_name: 'Domtest34', ssn: '243108282', dob: Date.new(1984, 3, 8))
    end

    let(:family_10) { FactoryBot.create(:family, :with_primary_family_member, person: person10) }
    let(:family10_id) { family_10.id }
    let(:family_member10_id) { BSON::ObjectId.new }
    let!(:application10) { FactoryBot.create(:financial_assistance_application, family_id: family10_id, hbx_id: '5979ec3cd7c2dc47ce000000', aasm_state: 'submitted') }
    let!(:ed) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application10, csr_percent_as_integer: nil, max_aptc: 0.0) }
    let!(:applicant10) do
      FactoryBot.create(:applicant, application: application10,
                                    family_member_id: family_member10_id,
                                    person_hbx_id: person10.hbx_id,
                                    ssn: '243108282',
                                    dob: Date.new(1984, 3, 8),
                                    first_name: 'Domtest34',
                                    last_name: 'Test',
                                    eligibility_determination_id: ed.id)
    end

    before do
      ed.update_attributes!(hbx_assigned_id: '205828')
      application10.add_eligibility_determination(message)
    end

    it 'should update eligibility_determination object' do
      expect(ed.max_aptc.to_f).to eq(47.78)
    end

    it 'should update applicant object' do
      expect(applicant10.is_ia_eligible).to be_truthy
    end
  end

  context 'relationships_complete' do
    let!(:applicant) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application,
                        family_member_id: BSON::ObjectId.new,
                        is_primary_applicant: true)
    end

    let(:set_up_relationships) do
      application.ensure_relationship_with_primary(applicant1, 'spouse')
      application.ensure_relationship_with_primary(applicant2, 'child')
      application.ensure_relationship_with_primary(applicant3, 'child')
      application.add_or_update_relationships(applicant1, applicant2, 'parent')
      application.add_or_update_relationships(applicant1, applicant3, 'parent')
      application.build_relationship_matrix
      application.save!
    end

    before do
      set_up_relationships
      @no_of_applicants = application.applicants.count
    end

    it 'should return true' do
      expect(application.relationships_complete?).to eq(true)
    end

    it 'should create a total of 12 relationships' do
      expect(application.relationships.count).to eq(@no_of_applicants * (@no_of_applicants - 1))
    end

    it 'should not create duplicate relationships' do
      set_up_relationships
      expect(application.relationships.count).to eq(@no_of_applicants * (@no_of_applicants - 1))
    end
  end

  context '#calculate_total_net_income_for_applicants' do
    let(:family_id)    { BSON::ObjectId.new }
    let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family_id, aasm_state: "draft") }
    let(:applicant) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application,
                        ssn: '889984400',
                        dob: Date.new(1993,12,9),
                        first_name: 'james',
                        last_name: 'bond')
    end

    let(:income) do
      FactoryBot.build(:financial_assistance_income, amount: 200, start_on: Date.new(2021,6,1), end_on: Date.new(2021, 6, 30), frequency_kind: "biweekly")
    end

    let(:deduction) do
      FactoryBot.build(:financial_assistance_deduction, amount: 100, start_on: Date.new(2021,6,1), end_on: Date.new(2021, 6, 30), frequency_kind: "biweekly")
    end

    context "application does not have any active applicants" do
      before do
        applicant.update_attributes(is_active: false)
      end

      it 'should not update net annual income for applicant' do
        application.calculate_total_net_income_for_applicants
        expect(applicant.net_annual_income).to eq nil
      end
    end

    context "No incomes and only deductions" do
      before do
        applicant.deductions << deduction
      end

      it 'should calculate and persist net annual income on applicant' do
        application.calculate_total_net_income_for_applicants
        expect(applicant.net_annual_income.to_f.ceil).to eq(-213)
      end
    end

    context "No deductions and only incomes" do
      before do
        applicant.incomes << income
      end

      it 'should calculate and persist net annual income on applicant' do
        application.calculate_total_net_income_for_applicants
        expect(applicant.net_annual_income.to_f.ceil).to eq 428
      end
    end

    context "Both deductions and incomes" do
      before do
        applicant.incomes << income
        applicant.deductions << deduction
      end

      it 'should calculate and persist net annual income on applicant' do
        application.calculate_total_net_income_for_applicants
        expect(applicant.net_annual_income.to_f.ceil).to eq 214
      end
    end
  end

  context 'other questions' do
    let!(:applicant) do
      FactoryBot.create(:applicant,
                        application: application,
                        dob: Date.today - 40.years,
                        is_applying_coverage: true,
                        is_primary_applicant: true,
                        is_pregnant: false,
                        has_unemployment_income: false,
                        is_physically_disabled: false,
                        is_post_partum_period: false,
                        is_self_attested_blind: true,
                        has_daily_living_help: true,
                        need_help_paying_bills: true,
                        is_ssn_applied: true,
                        family_member_id: BSON::ObjectId.new)
    end

    context 'other questions filled out with blind attestiation' do
      it 'should return true' do
        expect(applicant.other_questions_complete?).to eq(true)
      end
    end

    context 'other questions not filled out with blind attestiation' do

      before do
        applicant.is_self_attested_blind = nil
      end

      it 'should return false' do
        expect(applicant.other_questions_complete?).to eq(true)
      end
    end

  end

  context 'workflow_state_transitions' do
    context 'renewal_draft' do
      context 'event: submit' do
        before do
          application.update_attributes!(aasm_state: 'renewal_draft')
        end

        context 'from renewal_draft to submitted' do
          context 'guard success' do
            before do
              allow(application).to receive(:is_application_valid?).and_return(true)
              application.submit!
            end

            it 'should transition application to submit' do
              expect(application.reload.submitted?).to be_truthy
            end
          end

          context 'guard failure' do
            before do
              application.applicants[0].update_attributes(is_primary_applicant: true)
              application.submit!
            end

            it 'should not transition application to submit' do
              expect(application.reload.renewal_draft?).to be_truthy
            end
          end
        end

        context 'from renewal_draft to renewal_draft' do
          context 'guard success' do
            before do
              application.applicants[0].update_attributes(is_primary_applicant: true)
              application.submit!
            end

            it 'should transition application to renewal_draft' do
              expect(application.reload.renewal_draft?).to be_truthy
            end
          end
        end
      end

      context 'event: unsubmit' do
        context 'from submitted to renewal_draft' do
          before do
            application.assign_attributes(aasm_state: 'submitted')
            application.save!
          end

          context 'guard success' do
            before do
              application.workflow_state_transitions << WorkflowStateTransition.new(
                from_state: 'renewal_draft',
                to_state: 'submitted'
              )
              application.unsubmit!
            end

            it 'should transition application to renewal_draft' do
              expect(application.reload.renewal_draft?).to be_truthy
            end
          end

          context 'guard failure' do
            before do
              application.unsubmit!
            end

            it 'should not transition application to draft' do
              expect(application.reload.draft?).to be_truthy
            end
          end
        end
      end
    end

    context 'income_verification_extension_required' do
      context 'event: set_income_verification_extension_required' do
        before do
          application.update_attributes!(aasm_state: 'renewal_draft')
        end

        context 'from renewal_draft to income_verification_extension_required' do
          before do
            allow(application).to receive(:is_application_valid?).and_return(true)
            application.set_income_verification_extension_required!
          end

          it 'should transition application to income_verification_extension_required' do
            expect(application.reload.income_verification_extension_required?).to be_truthy
          end
        end
      end
    end
  end

  context 'advance_day' do
    let(:event) { Success(double) }
    let(:obj)  { ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new }

    before do
      allow(::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication).to receive(:new).and_return(obj)
      allow(obj).to receive(:build_event).and_return(event)
      allow(event.success).to receive(:publish).and_return(true)
    end

    it 'should not raise error with input date' do
      expect{ ::FinancialAssistance::Application.advance_day(TimeKeeper.date_of_record) }.not_to raise_error
    end

    it 'should not raise error without any input' do
      expect{ ::FinancialAssistance::Application.advance_day(nil) }.not_to raise_error
    end

    after :all do
      file_name = "#{Rails.root}/log/fa_application_advance_day_#{TimeKeeper.date_of_record.strftime('%Y_%m_%d')}.log"
      File.delete(file_name) if File.exist?(file_name)
    end
  end

  context 'attesations_complete' do
    context 'application invalid by one of the attestation' do
      [:is_requesting_voter_registration_application_in_mail, :is_renewal_authorized,
       :medicaid_terms, :report_change_terms, :medicaid_insurance_collection_terms,
       :parent_living_out_of_home_terms, :submission_terms].each do |key|
        before do
          application.send("#{key}=", nil)
          application.save!
        end

        it 'should return false' do
          expect(application.reload.attesations_complete?).to be_falsey
        end
      end
    end

    context 'application valid by attestation' do
      before do
        keys = [:is_requesting_voter_registration_application_in_mail,
                :is_renewal_authorized,
                :medicaid_terms,
                :report_change_terms,
                :medicaid_insurance_collection_terms,
                :parent_living_out_of_home_terms,
                :submission_terms,
                :attestation_terms]
        keys.each do |key|
          application.send("#{key}=", true)
        end
        application.save!
      end

      it 'should return true' do
        expect(application.reload.attesations_complete?).to be_truthy
      end
    end
  end

  context 'have_permission_to_renew' do
    context 'no value for aasistance_year' do
      before do
        application.update_attributes!({ assistance_year: nil,
                                         renewal_base_year: TimeKeeper.date_of_record.year })
      end

      it 'should return false' do
        expect(application.reload.have_permission_to_renew?).to be_falsey
      end
    end

    context 'no value for renewal_base_year' do
      before do
        application.update_attributes!({ assistance_year: TimeKeeper.date_of_record.year,
                                         renewal_base_year: nil })
      end

      it 'should return false' do
        expect(application.reload.have_permission_to_renew?).to be_falsey
      end
    end

    context 'expired permission for renewal' do
      before do
        application.update_attributes!({ assistance_year: TimeKeeper.date_of_record.year.next,
                                         renewal_base_year: TimeKeeper.date_of_record.year })
      end

      it 'should return false' do
        expect(application.reload.have_permission_to_renew?).to be_falsey
      end
    end

    context 'maximum number of years(5) permission for renewal' do
      before do
        application.update_attributes!({ assistance_year: TimeKeeper.date_of_record.year.next,
                                         renewal_base_year: TimeKeeper.date_of_record.year + 5 })
      end

      it 'should return true' do
        expect(application.reload.have_permission_to_renew?).to be_truthy
      end
    end

    context 'limited permission for renewal' do
      [1, 2, 3, 4, 5].each do |year|
        before do
          application.update_attributes!({ assistance_year: TimeKeeper.date_of_record.year.next,
                                           renewal_base_year: TimeKeeper.date_of_record.year + year })
        end

        it 'should return true' do
          expect(application.reload.have_permission_to_renew?).to be_truthy
        end
      end
    end
  end

  context 'set_renewal_base_year' do
    let(:applicant2) { application.applicants[1] }
    let(:applicant3) { application.applicants[2] }

    before do
      application.applicants.first.update_attributes!(is_primary_applicant: true)
      application.ensure_relationship_with_primary(applicant2, 'spouse')
      application.ensure_relationship_with_primary(applicant3, 'child')
      application.add_or_update_relationships(applicant2, applicant3, 'parent')
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
                                           county: '')]
        appl.save!
      end
      application.save!
    end

    context 'expired permission for renewal' do
      before do
        application.update_attributes!({ aasm_state: 'draft', is_renewal_authorized: false, years_to_renew: 0 })
        application.submit!
      end

      it 'should return value same as assistance_year' do
        expect(application.reload.renewal_base_year).to eq(application.reload.assistance_year)
      end
    end

    context 'maximum number of years(5) permission for renewal' do
      before do
        application.update_attributes!({ aasm_state: 'draft', is_renewal_authorized: true })
        application.submit!
      end

      it 'should return the sum of assistance_year & max of YEARS_TO_RENEW_RANGE' do
        expect(application.reload.renewal_base_year).to eq(
          application.reload.assistance_year +
            FinancialAssistance::Application::YEARS_TO_RENEW_RANGE.max
        )
      end
    end

    context 'limited permission for renewal' do
      before do
        application.update_attributes!({ aasm_state: 'draft', is_renewal_authorized: false, years_to_renew: 3 })
        application.submit!
      end

      it 'should return the sum of assistance_year & years_to_renew' do
        expect(application.reload.renewal_base_year).to eq(application.reload.assistance_year + 3)
      end
    end

    context 'for renewal_base_year already set' do
      before do
        application.update_attributes!(
          { aasm_state: 'draft',
            is_renewal_authorized: false,
            years_to_renew: 0,
            assistance_year: TimeKeeper.date_of_record.year.next,
            renewal_base_year: TimeKeeper.date_of_record.year.pred }
        )
        application.submit!
      end

      it 'should not update renewal_base_year' do
        expect(application.reload.renewal_base_year).to eq(TimeKeeper.date_of_record.year.pred)
        expect(application.reload.renewal_base_year).not_to eq(TimeKeeper.date_of_record.year.next)
      end
    end
  end

  describe 'calculate_total_net_income_for_applicants' do
    before do
      application.applicants.first.update_attributes!(is_primary_applicant: true, net_annual_income: nil)
      primary_appli = application.primary_applicant
      primary_appli.incomes << FinancialAssistance::Income.new(
        { title: 'Financial Income',
          kind: 'net_self_employment',
          amount: 500.00,
          start_on: Date.new(application.assistance_year || TimeKeeper.date_of_record.year.pred),
          frequency_kind: 'yearly' }
      )
      primary_appli.save!
      application.ensure_relationship_with_primary(applicant2, 'spouse')
      application.ensure_relationship_with_primary(applicant3, 'child')
      application.add_or_update_relationships(applicant2, applicant3, 'parent')
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
                                           county: '')]
        appl.save!
      end
      application.save!
    end

    context 'with existing value for net_annual_income' do
      before do
        application.primary_applicant.update_attributes!(net_annual_income: 1000.00)
        application.update_attributes!({ aasm_state: 'draft' })
        application.submit!
      end

      it 'should set value for net_annual_income again as there is existing value' do
        expect(application.primary_applicant.reload.net_annual_income.to_f).to eq(500.00)
      end
    end

    context 'without existing value for net_annual_income' do
      before do
        application.update_attributes!({ aasm_state: 'draft' })
        application.submit!
      end

      it 'should set value for net_annual_income as it is nil' do
        expect(application.primary_applicant.reload.net_annual_income.to_f).to eq(500.00)
      end
    end
  end

  describe 'build_relationship_matrix' do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:mitc_relationships).and_return(true)
    end

    let!(:application10) { FactoryBot.create(:financial_assistance_application, family_id: family_id) }
    let!(:applicant11) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application10,
                        family_member_id: BSON::ObjectId.new,
                        is_primary_applicant: true,
                        first_name: 'Primary')
    end
    let!(:applicant12) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application10,
                        family_member_id: BSON::ObjectId.new,
                        first_name: 'Wife')
    end
    let!(:applicant13) do
      FactoryBot.create(:financial_assistance_applicant,
                        application: application10,
                        family_member_id: BSON::ObjectId.new,
                        first_name: 'PrimaryFather')
    end

    context 'with valid case for FatherOrMotherInLaw/DaughterOrSonInLaw' do
      before do
        application10.ensure_relationship_with_primary(applicant12, 'spouse')
        application10.ensure_relationship_with_primary(applicant13, 'parent')
        application10.build_relationship_matrix
      end

      it 'should populate all the relationships' do
        expect(application10.reload.relationships_complete?).to be_truthy
      end

      it 'should create a relationship i.e., applicant12 is daughter_or_son_in_law to applicant13' do
        expect(
          application10.relationships.where(applicant_id: applicant12.id, relative_id: applicant13.id).first.kind
        ).to eq('daughter_or_son_in_law')
      end

      it 'should create a relationship i.e., applicant13 is father_or_mother_in_law to applicant12' do
        expect(
          application10.relationships.where(applicant_id: applicant13.id, relative_id: applicant12.id).first.kind
        ).to eq('father_or_mother_in_law')
      end
    end

    context 'with valid case for BrotherOrSisterInLaw' do
      context 'applicant13 is sibling to applicant12' do
        before do
          application10.ensure_relationship_with_primary(applicant12, 'spouse')
          application10.add_or_update_relationships(applicant12, applicant13, 'sibling')
          application10.build_relationship_matrix
        end

        it 'should populate all the relationships' do
          expect(application10.reload.relationships_complete?).to be_truthy
        end

        it 'should create a relationship i.e., applicant11 is brother_or_sister_in_law to applicant13' do
          expect(
            application10.relationships.where(applicant_id: applicant11.id, relative_id: applicant13.id).first.kind
          ).to eq('brother_or_sister_in_law')
        end

        it 'should create a relationship i.e., applicant13 is brother_or_sister_in_law to applicant11' do
          expect(
            application10.relationships.where(applicant_id: applicant13.id, relative_id: applicant11.id).first.kind
          ).to eq('brother_or_sister_in_law')
        end
      end

      context 'applicant13 is sibling to primary' do
        before do
          application10.ensure_relationship_with_primary(applicant12, 'spouse')
          application10.add_or_update_relationships(applicant13, applicant12, 'sibling')
          application10.build_relationship_matrix
        end

        it 'should populate all the relationships' do
          expect(application10.reload.relationships_complete?).to be_truthy
        end

        it 'should create a relationship i.e., applicant11 is brother_or_sister_in_law to applicant13' do
          expect(
            application10.relationships.where(applicant_id: applicant11.id, relative_id: applicant13.id).first.kind
          ).to eq('brother_or_sister_in_law')
        end

        it 'should create a relationship i.e., applicant13 is brother_or_sister_in_law to applicant11' do
          expect(
            application10.relationships.where(applicant_id: applicant13.id, relative_id: applicant11.id).first.kind
          ).to eq('brother_or_sister_in_law')
        end
      end
    end

    context 'with valid case for CousinLaw' do
      before do
        application10.ensure_relationship_with_primary(applicant12, 'aunt_or_uncle')
        application10.add_or_update_relationships(applicant12, applicant13, 'parent')
        application10.build_relationship_matrix
      end

      it 'should populate all the relationships' do
        expect(application10.relationships_complete?).to be_truthy
      end

      it 'should create a relationship i.e., applicant11 is cousin to applicant13' do
        expect(
          application10.relationships.where(applicant_id: applicant11.id, relative_id: applicant13.id).first.kind
        ).to eq('cousin')
      end

      it 'should create a relationship i.e., applicant13 is cousin to applicant11' do
        expect(
          application10.relationships.where(applicant_id: applicant13.id, relative_id: applicant11.id).first.kind
        ).to eq('cousin')
      end
    end

    context 'with valid case for DomesticPartnersChild' do
      before do
        application10.ensure_relationship_with_primary(applicant12, 'domestic_partner')
        application10.add_or_update_relationships(applicant12, applicant13, 'parent')
        application10.build_relationship_matrix
      end

      it 'should populate all the relationships' do
        expect(application10.relationships_complete?).to be_truthy
      end

      it 'should create a relationship i.e., applicant11 is parents_domestic_partner to applicant13' do
        expect(
          application10.relationships.where(applicant_id: applicant11.id, relative_id: applicant13.id).first.kind
        ).to eq('parents_domestic_partner')
      end

      it 'should create a relationship i.e., applicant13 is domestic_partners_child to applicant11' do
        expect(
          application10.relationships.where(applicant_id: applicant13.id, relative_id: applicant11.id).first.kind
        ).to eq('domestic_partners_child')
      end
    end

  end

  describe 'set_magi_medicaid_eligibility_request_errored' do
    context 'NoMagiMedicaidEngine' do
      before do
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:haven_determination).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:medicaid_gateway_determination).and_return(false)
        allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:verification_type_income_verification).and_return(false)
        application.update_attributes!(aasm_state: 'submitted')
      end

      it 'should not raise error NoMagiMedicaidEngine' do
        expect(FinancialAssistanceRegistry.feature_enabled?(:haven_determination)).to be_falsey
        expect(FinancialAssistanceRegistry.feature_enabled?(:medicaid_gateway_determination)).to be_falsey
        expect(application.set_magi_medicaid_eligibility_request_errored).to be_truthy
      end
    end
  end

  describe 'applicants_have_valid_addresses?' do
    context 'with valid home addresses' do
      before do
        application.applicants[0].update_attributes(is_primary_applicant: true)
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
                                             county: '')]
          appl.save!
        end
      end

      it 'should return true' do
        expect(application.applicants_have_valid_addresses?).to eq(true)
      end
    end

    context 'with work addresses only' do
      before do
        application.applicants[0].update_attributes(is_primary_applicant: true)
        application.applicants.each do |appl|
          appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                             :address_1 => '1111 Awesome Street NE',
                                             :address_2 => '#111',
                                             :address_3 => '',
                                             :city => 'Washington',
                                             :country_name => '',
                                             :kind => 'work',
                                             :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                             :zip => '20001',
                                             county: '')]
          appl.save!
        end
      end

      it 'should return false' do
        expect(application.applicants_have_valid_addresses?).to eq(false)
      end
    end

    context 'only primary applicant has home address and dependents with no address' do
      before do
        first_applicant = application.applicants.first
        first_applicant.update_attributes(is_primary_applicant: true)
        first_applicant.addresses = [FactoryBot.build(:financial_assistance_address,
                                                      :address_1 => '1111 Awesome Street NE',
                                                      :address_2 => '#111',
                                                      :address_3 => '',
                                                      :city => 'Washington',
                                                      :country_name => '',
                                                      :kind => 'home',
                                                      :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                                      :zip => '20001',
                                                      county: '')]
        first_applicant.save!
      end

      it 'should return false' do
        expect(application.applicants_have_valid_addresses?).to eq(false)
      end
    end

    context 'only primary applicant has home address and dependents with an address' do
      before do
        first_applicant = application.applicants.first
        first_applicant.update_attributes(is_primary_applicant: true)
        first_applicant.addresses = [FactoryBot.build(:financial_assistance_address,
                                                      :address_1 => '1111 Awesome Street NE',
                                                      :address_2 => '#111',
                                                      :address_3 => '',
                                                      :city => 'Washington',
                                                      :country_name => '',
                                                      :kind => 'home',
                                                      :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                                      :zip => '20001',
                                                      county: '')]

        dependents = application.applicants.where(is_primary_applicant: false)
        dependents.each do |dependent|
          dependent.addresses = [FactoryBot.build(:financial_assistance_address,
                                                  :address_1 => '1111 Awesome Street NE',
                                                  :address_2 => '#111',
                                                  :address_3 => '',
                                                  :city => 'test',
                                                  :country_name => '',
                                                  :kind => 'home',
                                                  :state => 'co',
                                                  :zip => '40001',
                                                  county: '')]
          dependent.save!
        end
        first_applicant.save!
        application.save!
      end

      it 'should return true' do
        expect(application.applicants_have_valid_addresses?).to eq(true)
      end
    end

    context 'only primary applicant has home address and dependents with work address' do
      before do
        first_applicant = application.applicants.first
        first_applicant.update_attributes(is_primary_applicant: true)
        first_applicant.addresses = [FactoryBot.build(:financial_assistance_address,
                                                      :address_1 => '1111 Awesome Street NE',
                                                      :address_2 => '#111',
                                                      :address_3 => '',
                                                      :city => 'Washington',
                                                      :country_name => '',
                                                      :kind => 'home',
                                                      :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                                      :zip => '20001',
                                                      county: '')]

        dependents = application.applicants.where(is_primary_applicant: false)
        dependents.each do |dependent|
          dependent.addresses = [FactoryBot.build(:financial_assistance_address,
                                                  :address_1 => '1111 Awesome Street NE',
                                                  :address_2 => '#111',
                                                  :address_3 => '',
                                                  :city => 'test',
                                                  :country_name => '',
                                                  :kind => 'work',
                                                  :state => 'co',
                                                  :zip => '40001',
                                                  county: '')]
          dependent.save!
        end
        first_applicant.save!
        application.save!
      end

      it 'should return true' do
        expect(application.applicants_have_valid_addresses?).to eq(false)
      end
    end
  end

  describe 'set_magi_medicaid_eligibility_request_errored' do
    before do
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:haven_determination).and_return(haven_determination)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:medicaid_gateway_determination).and_return(medicaid_gateway_determination)
      allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:verification_type_income_verification).and_return(false)
      create_instate_addresses
      create_relationships
      application.update_attributes!(aasm_state: app_state)
      application.submit!
    end

    context 'haven_determination' do
      let(:haven_determination) { true }
      let(:medicaid_gateway_determination) { false }
      let(:app_state) { 'haven_magi_medicaid_eligibility_request_errored' }

      it 'should transition application to submitted' do
        expect(application.reload.submitted?).to be_truthy
      end
    end

    context 'medicaid_gateway_determination' do
      let(:haven_determination) { false }
      let(:medicaid_gateway_determination) { true }
      let(:app_state) { 'mitc_magi_medicaid_eligibility_request_errored' }

      it 'should transition application to submitted' do
        expect(application.reload.submitted?).to be_truthy
      end
    end
  end

  describe 'update_or_build_relationship' do
    let(:create_individual_rels) do
      application.applicants.first.update_attributes!(is_primary_applicant: true) unless application.primary_applicant.present?
      application.update_or_build_relationship(application.primary_applicant, applicant2, 'spouse')
      application.update_or_build_relationship(applicant2, application.primary_applicant, 'spouse')
      application.update_or_build_relationship(application.primary_applicant, applicant3, 'child')
      application.update_or_build_relationship(applicant3, application.primary_applicant, 'parent')
      application.update_or_build_relationship(applicant2, applicant3, 'parent')
      application.update_or_build_relationship(applicant3, applicant2, 'child')
      application.save!
    end

    it 'should create specific number of relationship objects only' do
      create_individual_rels
      applicants_count = application.reload.applicants.count
      expect(application.reload.relationships.count).to eq(applicants_count * (applicants_count - 1))
    end

    it 'should not create more number of relationship that the expected even if we try to call the creation multiple times' do
      create_individual_rels
      create_individual_rels
      applicants_count = application.reload.applicants.count
      expect(application.reload.relationships.count).to eq(applicants_count * (applicants_count - 1))
    end
  end

  # add_relationship(predecessor, successor, relationship_kind, destroy_relation = false)
  describe 'add_relationship' do
    context 'destroy_relation set to true with different relationship kind' do
      before do
        create_relationships
        application.add_relationship(application.primary_applicant, applicant2, 'parent', true)
      end

      it 'should just have 4 relationships as it removes all the other relationships that are mapped to primary_applicant' do
        expect(application.reload.relationships.count).to eq(4)
      end
    end

    context 'destroy_relation set to true with same relationship kind' do
      before do
        create_relationships
        application.add_relationship(application.primary_applicant, applicant2, 'spouse', true)
      end

      it 'should not remove any relationships as same relationship kind was sent as i/p' do
        expect(application.reload.relationships.count).to eq(6)
      end
    end
  end
end
