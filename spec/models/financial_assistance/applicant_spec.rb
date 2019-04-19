require 'rails_helper'

RSpec.describe FinancialAssistance::Applicant, type: :model do
  before :each do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end

  let!(:person1) { FactoryGirl.create(:person, :with_consumer_role, dob: TimeKeeper.date_of_record - 46.years) }
  let!(:person2) { FactoryGirl.create(:person, :with_consumer_role, dob: '1972-04-04'.to_date) }
  let!(:family)  { family = FactoryGirl.create(:family, :with_primary_family_member, person: person1)
    FactoryGirl.create(:family_member, family: family, person: person2)
    person1.person_relationships.create!(successor_id: person2.id, predecessor_id: person1.id, kind: 'spouse', family_id: family.id)
    person2.person_relationships.create!(successor_id: person1.id, predecessor_id: person2.id, kind: 'spouse', family_id: family.id)
    family.save!
    family }
  let!(:family_member1) { family.primary_applicant }
  let!(:family_member2) { family.family_members.second }
  let!(:application) { FactoryGirl.create(:application, family: family) }
  let!(:household) { family.households.first }
  let(:coverage_household1) { household.coverage_households.first }
  let(:coverage_household2) { household.coverage_households.second }
  let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: household, aasm_state: 'coverage_selected', coverage_household_id: household.coverage_households.first.id) }
  let!(:hbx_enrollment_member) { FactoryGirl.create(:hbx_enrollment_member, hbx_enrollment: hbx_enrollment, applicant_id: family_member1.id, eligibility_date: TimeKeeper.date_of_record) }
  let!(:tax_household1) { FactoryGirl.create(:tax_household, application_id: application.id, household: household, effective_ending_on: nil) }
  let!(:eligibility_determination1) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household1, source: 'Curam', csr_eligibility_kind: 'csr_87') }
  let!(:eligibility_determination2) { FactoryGirl.create(:eligibility_determination, tax_household: tax_household1, source: 'Haven') }
  let!(:applicant1) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member1.id) }
  let!(:applicant2) { FactoryGirl.create(:applicant, tax_household_id: tax_household1.id, application: application, family_member_id: family_member2.id, aasm_state: 'verification_outstanding') }
  let!(:assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant1, status: 'pending') }

  describe '#modelFeilds' do
    it { is_expected.to have_field(:assisted_income_validation).of_type(String).with_default_value_of('pending') }
    it { is_expected.to have_field(:assisted_mec_validation).of_type(String).with_default_value_of('pending') }
    it { is_expected.to have_field(:assisted_income_reason).of_type(String) }
    it { is_expected.to have_field(:assisted_mec_reason).of_type(String) }

    it { is_expected.to have_field(:aasm_state).of_type(String).with_default_value_of(:unverified) }

    it { is_expected.to have_field(:family_member_id).of_type(BSON::ObjectId) }
    it { is_expected.to have_field(:tax_household_id).of_type(BSON::ObjectId) }

    it { is_expected.to have_field(:is_active).of_type(Mongoid::Boolean).with_default_value_of(true) }

    it { is_expected.to have_field(:has_fixed_address).of_type(Mongoid::Boolean).with_default_value_of(true) }
    it { is_expected.to have_field(:is_living_in_state).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_temp_out_of_state).of_type(Mongoid::Boolean).with_default_value_of(false) }

    it { is_expected.to have_field(:is_required_to_file_taxes).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:tax_filer_kind).of_type(String).with_default_value_of('tax_filer') }
    it { is_expected.to have_field(:is_joint_tax_filing).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_claimed_as_tax_dependent).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:claimed_as_tax_dependent_by).of_type(BSON::ObjectId) }

    it { is_expected.to have_field(:is_ia_eligible).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_medicaid_chip_eligible).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_non_magi_medicaid_eligible).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_totally_ineligible).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_without_assistance).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:has_income_verification_response).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:has_mec_verification_response).of_type(Mongoid::Boolean).with_default_value_of(false) }

    it { is_expected.to have_field(:magi_medicaid_monthly_household_income).of_type(Money).with_default_value_of(0.00) }
    it { is_expected.to have_field(:magi_medicaid_monthly_income_limit).of_type(Money).with_default_value_of(0.00) }

    it { is_expected.to have_field(:magi_as_percentage_of_fpl).of_type(Float).with_default_value_of(0.00) }
    it { is_expected.to have_field(:magi_medicaid_type).of_type(String) }
    it { is_expected.to have_field(:magi_medicaid_category).of_type(String) }
    it { is_expected.to have_field(:medicaid_household_size).of_type(Integer) }

    it { is_expected.to have_field(:is_magi_medicaid).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_medicare_eligible).of_type(Mongoid::Boolean).with_default_value_of(false) }

    it { is_expected.to have_field(:is_student).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:student_kind).of_type(String) }
    it { is_expected.to have_field(:student_school_kind).of_type(String) }
    it { is_expected.to have_field(:student_status_end_on).of_type(String) }

    it { is_expected.to have_field(:is_self_attested_blind).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_self_attested_disabled).of_type(Mongoid::Boolean).with_default_value_of(false) }

    it { is_expected.to have_field(:is_self_attested_long_term_care).of_type(Mongoid::Boolean).with_default_value_of(false) }

    it { is_expected.to have_field(:is_veteran).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_refugee).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_trafficking_victim).of_type(Mongoid::Boolean).with_default_value_of(false) }

    it { is_expected.to have_field(:is_former_foster_care).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:age_left_foster_care).of_type(Integer).with_default_value_of(0) }
    it { is_expected.to have_field(:foster_care_us_state).of_type(String) }
    it { is_expected.to have_field(:had_medicaid_during_foster_care).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_pregnant).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_enrolled_on_medicaid).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_post_partum_period).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:children_expected_count).of_type(Integer).with_default_value_of(0) }
    it { is_expected.to have_field(:pregnancy_due_on).of_type(Date) }
    it { is_expected.to have_field(:pregnancy_end_on).of_type(Date) }

    it { is_expected.to have_field(:is_subject_to_five_year_bar).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_five_year_bar_met).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_forty_quarters).of_type(Mongoid::Boolean).with_default_value_of(false) }
    it { is_expected.to have_field(:is_ssn_applied).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:non_ssn_apply_reason).of_type(String) }

    it { is_expected.to have_field(:moved_on_or_after_welfare_reformed_law).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_veteran_or_active_military).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_spouse_or_dep_child_of_veteran_or_active_military).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_currently_enrolled_in_health_plan).of_type(Mongoid::Boolean) }

    it { is_expected.to have_field(:has_daily_living_help).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:need_help_paying_bills).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_resident_post_092296).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:is_vets_spouse_or_child).of_type(Mongoid::Boolean) }

    it { is_expected.to have_field(:has_job_income).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:has_self_employment_income).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:has_other_income).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:has_deductions).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:has_enrolled_health_coverage).of_type(Mongoid::Boolean) }
    it { is_expected.to have_field(:has_eligible_health_coverage).of_type(Mongoid::Boolean) }

    it { is_expected.to have_field(:workflow).of_type(Hash).with_default_value_of({}) }
  end

  describe '#Associations' do
    it 'embedded many application' do
      assc = described_class.reflect_on_association(:application)
      expect(assc.macro).to eq :embedded_in
    end

    it 'embeds many incomes' do
      assc = described_class.reflect_on_association(:incomes)
      expect(assc.macro).to eq :embeds_many
    end

    it 'embeds many deductions' do
      assc = described_class.reflect_on_association(:deductions)
      expect(assc.macro).to eq :embeds_many
    end

    it 'embeds many benefits' do
      assc = described_class.reflect_on_association(:benefits)
      expect(assc.macro).to eq :embeds_many
    end

    it 'embeds many assisted_verifications' do
      assc = described_class.reflect_on_association(:assisted_verifications)
      expect(assc.macro).to eq :embeds_many
    end

    it 'embeds many workflow_state_transitions' do
      assc = described_class.reflect_on_association(:workflow_state_transitions)
      expect(assc.macro).to eq :embeds_many
    end
  end

  describe '#Constants' do
    it 'should have tax filer kinds constant' do
      subject.class.should be_const_defined(:TAX_FILER_KINDS)
      expect(described_class::TAX_FILER_KINDS).to eq(%w[tax_filer single joint separate dependent non_filer])
    end

    it 'should have student kinds constant' do
      subject.class.should be_const_defined(:STUDENT_KINDS)
      student_kinds = %w[ dropped_out elementary english_language_institute full_time ged graduated graduate_school half_time junior_school
        not_in_school open_university part_time preschool primary secondary technical undergraduate vocational vocational_tech ]
        expect(described_class::STUDENT_KINDS).to eq(student_kinds)
    end

    it 'should have student school kinds constant' do
      subject.class.should be_const_defined(:STUDENT_SCHOOL_KINDS)
      school_student_kinds = %w[
        english_language_institute
        elementary
        equivalent_vocational_tech
        graduate_school
        ged
        high_school
        junior_school
        open_university
        pre_school
        primary
        technical
        undergraduate
        vocational
      ]
      expect(described_class::STUDENT_SCHOOL_KINDS).to eq(school_student_kinds)
    end

    it 'should have income validation states constant' do
      subject.class.should be_const_defined(:INCOME_VALIDATION_STATES)
      expect(described_class::INCOME_VALIDATION_STATES).to eq(%w[na valid outstanding pending])
    end

    it 'should have mec validation states constant' do
      subject.class.should be_const_defined(:MEC_VALIDATION_STATES)
      expect(described_class::MEC_VALIDATION_STATES).to eq(%w[na valid outstanding pending])
    end

    it 'should have driver question attributes constant' do
      subject.class.should be_const_defined(:DRIVER_QUESTION_ATTRIBUTES)
      expect(described_class::DRIVER_QUESTION_ATTRIBUTES).to eq([:has_job_income, :has_self_employment_income, :has_other_income, :has_deductions, :has_enrolled_health_coverage, :has_eligible_health_coverage])
    end
  end

  describe '#is_ia_eligible?' do
    it 'should return true if is_ia_eligible attirbute is true' do
      applicant1.update_attributes(is_ia_eligible: true)
      expect(applicant1.is_ia_eligible?).to be_truthy
    end
    it 'should return false if is_ia_eligible attirbute is false' do
      applicant1.update_attributes(is_ia_eligible: false)
      expect(applicant1.is_ia_eligible?).to be_falsey
    end
  end

  describe '#non_ia_eligible?' do
    it 'should return true if is_ia_eligible attirbute is false' do
      applicant1.update_attributes(is_ia_eligible: false)
      applicant1.update_attributes(is_medicaid_chip_eligible: true)
      expect(applicant1.non_ia_eligible?).to be_truthy
    end
    it 'should return false if is_ia_eligible attirbute is true' do
      applicant1.update_attributes(is_ia_eligible: true)
      applicant1.update_attributes(is_medicaid_chip_eligible: true)
      expect(applicant1.is_ia_eligible?).to be_falsey
    end
  end

  describe '#is_medicaid_chip_eligible?' do
    it 'should return true if is_medicaid_chip_eligible attirbute is true' do
      applicant1.update_attributes(is_medicaid_chip_eligible: true)
      expect(applicant1.is_medicaid_chip_eligible?).to be_truthy
    end
    it 'should return false if is_medicaid_chip_eligible attirbute is false' do
      applicant1.update_attributes(is_medicaid_chip_eligible: false)
      expect(applicant1.is_medicaid_chip_eligible?).to be_falsey
    end
  end

  describe '#is_tax_dependent?' do
    it 'should return true if is_tax_dependent attirbute is preseent' do
      applicant1.update_attributes(tax_filer_kind: "tax_dependent")
      expect(applicant1.is_tax_dependent?).to be_truthy
    end
    it 'should return false if is_tax_dependent attirbute is not preseent' do
      expect(applicant1.is_tax_dependent?).to be_falsey
    end
  end

  describe '#tax_filing?' do
    it 'should return true if tax_filing attirbute is true' do
      applicant1.update_attributes(is_required_to_file_taxes: true)
      expect(applicant1.tax_filing?).to be_truthy
    end
    it 'should return false if tax_filing attirbute is false' do
      expect(applicant1.tax_filing?).to be_falsey
    end
  end

  describe '#is_claimed_as_tax_dependent?' do
    it 'should return true if is_claimed_as_tax_dependent attirbute is true' do
      applicant1.update_attributes(is_claimed_as_tax_dependent: true)
      expect(applicant1.is_claimed_as_tax_dependent?).to be_truthy
    end
    it 'should return false if is_claimed_as_tax_dependent attirbute is false' do
      expect(applicant1.is_claimed_as_tax_dependent?).to be_falsey
    end
  end

  describe '#is_not_in_a_tax_household?' do
    it 'should return true if tax_household_id is nil' do
      applicant1.update_attributes(tax_household_id: nil)
      expect(applicant1.is_not_in_a_tax_household?).to be_truthy
    end
    it 'should return false if tax_household_id is preseent' do
      expect(applicant1.is_not_in_a_tax_household?).to be_falsey
    end
  end

  describe '#valid_mec_response' do
    it 'should update_attributes to valid' do
      applicant1.valid_mec_response
      expect(applicant1.assisted_mec_validation).to eq 'valid'
    end
  end

  describe '#invalid_mec_response' do
    it 'should update_attributes to outstanding' do
      applicant1.invalid_mec_response
      expect(applicant1.assisted_mec_validation).to eq "outstanding"
    end
  end

  describe '#valid_income_response' do
    it 'should return true if assisted_income_validation attirbute is valid' do
      applicant1.valid_income_response
      expect(applicant1.assisted_income_validation).to eq 'valid'
    end
  end

  describe '#invalid_income_response' do
    it 'should return true if assisted_income_validation attirbute is outstanding' do
      applicant1.invalid_income_response
      expect(applicant1.assisted_income_validation).to eq "outstanding"
    end
  end

  describe '#has_spouse' do
    it 'should return true if spouse is preseent' do
      expect(applicant1.has_spouse).to be_truthy
    end
  end

  describe '#immigration_status?' do
    it 'should return citizen_status' do
      expect(applicant1.immigration_status?).to eq("us_citizen")
    end
  end

  describe '#is_without_assistance?' do
    it 'should return true if is_without_assistance is true' do
      applicant1.update_attributes(is_without_assistance: true)
      expect(applicant1.is_without_assistance?).to be_truthy
    end
    it 'should return false if is_without_assistance is false' do
      expect(applicant1.is_without_assistance?).to be_falsey
    end
  end

  describe '#is_primary_applicant?' do
    it 'should return true if applicacnt is primary' do
      expect(applicant1.is_primary_applicant?).to be_truthy
    end
    it 'should return false if applicacnt is not primary' do
      expect(applicant2.is_primary_applicant?).to be_falsey
    end
  end

  describe '#family_member' do
    it 'should return family_member1' do
      expect(applicant1.family_member).to eq(family_member1)
    end
    it 'should return family_member2' do
      expect(applicant2.family_member).to eq(family_member2)
    end
  end

  describe '#consumer_role' do
    it 'should return consumer_role for person1' do
      expect(applicant1.consumer_role).to eq(person1.consumer_role)
    end
    it 'should return consumer_role for person2' do
      expect(applicant2.consumer_role).to eq(person2.consumer_role)
    end
  end

  describe '#person' do
    context 'with person1 and person2' do
      it 'should return person1' do
        expect(applicant1.person).to eq(person1)
      end
      it 'should return person2' do
        expect(applicant2.person).to eq(person2)
      end
    end
  end

  describe '#family' do
    context 'with applicant1 and applicant2' do
      it 'should return family' do
        expect(applicant1.family).to eq(family)
      end
      it 'should return family' do
        expect(applicant2.family).to eq(family)
      end
    end
  end

  describe '#tobacco_user' do
    context 'with applicant1' do
      it 'should return unknown ' do
        expect(applicant1.tobacco_user).to eq("unknown")
      end
    end
  end

  describe '#tax_household' do
    it 'should return tax_household ' do
      expect(applicant1.tax_household).to eq(tax_household1)
    end
  end

  describe '#age_on_effective_date' do
    context 'with applicant1' do
      it 'should return age' do
        expect(applicant1.age_on_effective_date).to eq(46)
      end
    end
  end

  describe '#eligibility_determinations' do
    context 'with applicant1' do
      it 'should return eligibility_determinations' do
        expect(applicant1.eligibility_determinations).to eq(applicant1.tax_household.eligibility_determinations)
      end
      it 'should verify count eligibility_determinations' do
        expect(applicant1.eligibility_determinations.count).to eq(2)
      end
    end
  end

  describe '#preferred_eligibility_determination' do
    context 'with applicant1' do
      it 'should return eligibility_determination1' do
        expect(applicant1.preferred_eligibility_determination).to eq(eligibility_determination1)
      end
    end
  end

  describe '#age_of_the_applicant' do
    it 'should return age' do
      expect(applicant1.age_of_the_applicant).to eq(46)
    end
  end

  describe '#has_income?' do
    it 'should return true if has_job_income' do
      applicant1.update_attributes(has_job_income: true)
      expect(applicant1.has_income?).to eq(true)
    end
    it 'should return true if has_self_employment_income' do
      applicant1.update_attributes(has_self_employment_income: true)
      expect(applicant1.has_income?).to eq(true)
    end
    it 'should return true if has_other_income' do
      applicant1.update_attributes(has_other_income: true)
      expect(applicant1.has_income?).to eq(true)
    end
  end

  describe '#assisted_income_verified?' do
    it 'should return true if assisted_income_validation attirbute is valid' do
      applicant1.update_attributes(assisted_income_validation: 'valid')
      expect(applicant1.assisted_income_verified?).to be_truthy
    end
  end

  describe '#assisted_mec_verified?' do
    it 'should return true if assisted_mec_validation attirbute is valid' do
      applicant1.update_attributes(assisted_mec_validation: 'valid')
      expect(applicant1.assisted_mec_verified?).to be_truthy
    end
  end

  describe '#income_valid?' do
    context 'when assisted_income_validation attirbute is valid' do
      it 'should return true' do
        applicant1.update_attributes(assisted_income_validation: 'valid')
        expect(applicant1.income_valid?).to be_truthy
      end
    end
  end

  describe '#mec_valid?' do
    context 'when assisted_mec_validation attirbute is valid' do
      it 'should return true if assisted_mec_validation attirbute is valid' do
        applicant1.update_attributes(assisted_mec_validation: 'valid')
        expect(applicant1.mec_valid?).to be_truthy
      end
    end
  end

  describe '#eligible_for_faa?' do
    it 'should return true if applicant1 is eligible_for_faa' do
      expect(applicant1.eligible_for_faa?).to eq true
    end
    it 'should return true if applicant2 is eligible_for_faa' do
      expect(applicant2.eligible_for_faa?).to eq true
    end
  end

  describe 'with wrong arguments' do
    let(:params) {{application: application, tax_filer_kind: 'test', has_fixed_address: nil}}

    it 'should not save' do
      expect(described_class.create(**params).valid?).to be_falsey
    end
  end

  describe 'applicants for an application - event transitions', dbclean: :after_each do
    before :each do
      coverage_household1.update_attributes!(aasm_state: 'enrolled')
      coverage_household2.update_attributes!(aasm_state: 'enrolled')
    end

    context 'applicants with tax household and multiple eligibility_determinations' do
      it 'should return only one eligibility determination and that should be preferred' do
        expect(applicant1.preferred_eligibility_determination).to eq eligibility_determination1
        expect(applicant1.preferred_eligibility_determination).not_to eq eligibility_determination2
      end

      it 'should equal to the csr_eligibility_kind of preferred_eligibility_determination' do
        expect(application.current_csr_eligibility_kind(tax_household1.id)).to eq eligibility_determination1.csr_eligibility_kind
        expect(application.current_csr_eligibility_kind(tax_household1.id)).not_to eq eligibility_determination2.csr_eligibility_kind
      end

      it 'should take eligibility determination with source Curam as preferred eligibility determination and not haven' do
        expect(applicant1.preferred_eligibility_determination.source).to eq 'Curam'
        expect(applicant1.preferred_eligibility_determination.source).not_to eq 'Haven'
      end

      it 'should return al the eligibility determinations for that applicant' do
        expect(applicant1.eligibility_determinations).to eq [eligibility_determination1, eligibility_determination2]
        expect(applicant1.eligibility_determinations).not_to eq [eligibility_determination1, eligibility_determination1]
      end

      it 'should return the dob of the person associated to the applicant' do
        now = TimeKeeper.date_of_record
        dob = applicant2.person.dob
        current_age = now.year - dob.year - (now.strftime('%m%d') < dob.strftime('%m%d') ? 1 : 0)
        expect(applicant2.age_on_effective_date).to eq current_age
        expect(applicant2.age_on_effective_date).not_to eq 25
      end

      it 'should return the right tax household for a given applicant' do
        expect(applicant1.tax_household).to eq tax_household1
        expect(applicant1.tax_household).not_to eq nil
      end

      it 'should return right family_member and family' do
        expect(applicant1.family).to eq family
        expect(applicant1.family_member).to eq family_member1
        expect(applicant1.family_member).not_to eq family_member2
      end

      it 'should return true if the family_member associated to the applicant is the primary of the family' do
        expect(applicant1.is_primary_applicant?).to eq true
        expect(applicant1.is_primary_applicant?).not_to eq false
      end
    end

    context 'state transitions and eligibility notification for hbx_enrollment and coverage_household' do

      context 'from state unverified' do
        it 'should return unverified state as a default state' do
          expect(applicant1.aasm_state).to eq 'unverified'
        end

        context 'for notify_of_eligibility_change and aasm_state changes on_event: income_outstanding, verification_outstanding' do
          before :each do
            applicant1.income_outstanding!
          end

          it 'should transition from unverified to verification_outstanding' do
            expect(applicant1.aasm_state).to eq 'verification_outstanding'
          end

          it 'should also transition from enrolled to unverified for CoverageHousehold' do
            coverage_household1.reload
            expect(coverage_household1.aasm_state).to eq 'unverified'
          end

          it 'should also add the transition to workflow_state_transitions of the applicant' do
            expect(applicant1.workflow_state_transitions.last.from_state).to eq 'unverified'
            expect(applicant1.workflow_state_transitions.last.to_state).to eq 'verification_outstanding'
          end
        end

        context 'for notify_of_eligibility_change and aasm_state changes on_event: income_valid, verification_pending' do
          before :each do
            applicant1.income_valid!
          end

          it 'should transition from unverified to verification_outstanding' do
            expect(applicant1.aasm_state).to eq 'verification_pending'
          end

          it 'should also transition from enrolled to unverified for CoverageHousehold' do
            coverage_household1.reload
            expect(coverage_household1.aasm_state).to eq 'unverified'
          end

          it 'should also add the transition to workflow_state_transitions of the applicant' do
            expect(applicant1.workflow_state_transitions.last.from_state).to eq 'unverified'
            expect(applicant1.workflow_state_transitions.last.to_state).to eq 'verification_pending'
          end
        end

        context 'for notify_of_eligibility_change and aasm_state changes on_event: income_valid, fully_verified' do
          let!(:assisted_verification) { FactoryGirl.create(:assisted_verification, applicant: applicant1, verification_type: 'MEC', status: 'verified') }

          before :each do
            applicant1.income_valid!
          end

          it 'should transition from unverified to verification_outstanding' do
            expect(applicant1.aasm_state).to eq 'fully_verified'
          end

          it 'should also add the transition to workflow_state_transitions of the applicant' do
            expect(applicant1.workflow_state_transitions.last.from_state).to eq 'unverified'
            expect(applicant1.workflow_state_transitions.last.to_state).to eq 'fully_verified'
          end
        end
      end

      context 'from state verification_outstanding' do
        it 'should transition to verification_outstanding' do
          expect(applicant2.aasm_state).to eq 'verification_outstanding'
          applicant2.income_outstanding!
          expect(applicant2.aasm_state).to eq 'verification_outstanding'
        end

        it 'should transition to fully_verified' do
          applicant2.assisted_verifications.create!(applicant: applicant2, verification_type: 'MEC', status: 'verified')
          expect(applicant2.aasm_state).to eq 'verification_outstanding'
          applicant2.income_valid!
          expect(applicant2.aasm_state).to eq 'fully_verified'
        end
      end

      context 'from state verification_pending' do
        before :each do
          applicant2.update_attributes!(aasm_state: 'verification_pending')
        end

        it 'should transition to verification_outstanding' do
          expect(applicant2.aasm_state).to eq 'verification_pending'
          applicant2.income_outstanding!
          expect(applicant2.aasm_state).to eq 'verification_outstanding'
        end

        it 'should transition to fully_verified' do
          applicant2.assisted_verifications.create!(applicant: applicant2, verification_type: 'MEC', status: 'verified')
          expect(applicant2.aasm_state).to eq 'verification_pending'
          applicant2.income_valid!
          expect(applicant2.aasm_state).to eq 'fully_verified'
        end
      end

      context 'from fully_verified' do
        it 'should transition to fully_verified' do
          applicant2.update_attributes!(aasm_state: 'fully_verified')
          expect(applicant2.aasm_state).to eq 'fully_verified'
          applicant2.income_valid!
          expect(applicant2.aasm_state).to eq 'fully_verified'
        end
      end
    end

    context 'validation of an Applicant in submission context' do
      driver_qns = described_class::DRIVER_QUESTION_ATTRIBUTES

      before(:each) do
        allow_any_instance_of(described_class).to receive(:is_required_to_file_taxes).and_return(true)
        allow_any_instance_of(described_class).to receive(:is_claimed_as_tax_dependent).and_return(false)
        allow_any_instance_of(described_class).to receive(:is_joint_tax_filing).and_return(false)
        allow_any_instance_of(described_class).to receive(:is_pregnant).and_return(false)
        allow_any_instance_of(described_class).to receive(:is_self_attested_blind).and_return(false)
        allow_any_instance_of(described_class).to receive(:has_daily_living_help).and_return(false)
        allow_any_instance_of(described_class).to receive(:need_help_paying_bills).and_return(false)
        applicant1.update_attributes!(is_required_to_file_taxes: true, is_joint_tax_filing: true, has_job_income: true)
        driver_qns.each { |attribute| applicant1.send("#{attribute}=", false) }
      end

      driver_qns.each do |attribute|
        instance_check_method = attribute.to_s.gsub('has_', '') + '_exists?'

        it 'should NOT validate applicant when attribute is nil' do
          applicant1.send("#{attribute}=", nil)
          expect(applicant1.applicant_validation_complete?).to eq false
        end

        it 'should validate applicant when some Driver Question attribute is FALSE and there is No Instance of that type' do
          applicant1.send("#{attribute}=", false)
          allow(applicant1).to receive(instance_check_method).and_return false
          expect(applicant1.applicant_validation_complete?).to eq true
        end

        it 'should NOT validate applicant when some Driver Question attribute is TRUE but there is No Instance of that type' do
          applicant1.send("#{attribute}=", true)
          allow(applicant1).to receive(instance_check_method).and_return false
          expect(applicant1.applicant_validation_complete?).to eq false
        end

        it 'should NOT validate applicant when some Driver Question attribute is FALSE but there is an Instance of that type' do
          applicant1.send("#{attribute}=", false)
          allow(applicant1).to receive(instance_check_method).and_return true
          expect(applicant1.applicant_validation_complete?).to eq false
        end

        it 'should validate applicant for former_foster_care, if age is between 18 and 25 and is_former_foster_care is not nil' do
          applicant1.send("#{attribute}=", false)
          now = TimeKeeper.date_of_record
          applicant1.person.dob = Date.new((now.year - 20), 1, 1)
          expect(applicant1.is_former_foster_care).to eq nil
          applicant1.update_attributes!(is_former_foster_care: true)
          expect(applicant1.applicant_validation_complete?).to eq true
        end

        it 'should validate applicant for former_foster_care, if age is between 18 and 25 and is_former_foster_care is nil' do
          applicant1.send("#{attribute}=", false)
          now = TimeKeeper.date_of_record
          applicant1.person.dob = Date.new((now.year - 20), 1, 1)
          expect(applicant1.is_former_foster_care).to eq nil
          expect(applicant1.applicant_validation_complete?).to eq false
        end

        it 'should not validate applicant for former_foster_care, if age is not between 18 and 25' do
          applicant1.send("#{attribute}=", false)
          now = TimeKeeper.date_of_record
          applicant1.person.dob = Date.new((now.year - 30), 1, 1)
          expect(applicant1.is_former_foster_care).to eq nil
          expect(applicant1.applicant_validation_complete?).to eq true
        end
      end
    end
  end
end
