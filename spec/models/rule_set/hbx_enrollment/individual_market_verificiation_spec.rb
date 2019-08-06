require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe RuleSet::HbxEnrollment::IndividualMarketVerification, :if => ExchangeTestingConfigurationHelper.individual_market_is_enabled?, dbclean: :around_each do
  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup initial benefit application'

  subject { RuleSet::HbxEnrollment::IndividualMarketVerification.new(enrollment) }
  let(:effective_on) { TimeKeeper.date_of_record.beginning_of_year }
  let(:enrollment_status) { 'coverage_selected' }
  let(:product) {FactoryBot.build(:benefit_markets_products_product, benefit_market_kind: 'aca_individual') }

  let(:family)        { FactoryBot.create(:family, :with_primary_family_member) }
  let(:enrollment)    { FactoryBot.create(:hbx_enrollment,
                                          household: family.latest_household,
                                          family: family,
                                          effective_on: effective_on,
                                          kind: "individual",
                                          submitted_at: effective_on - 10.days,
                                          aasm_state: enrollment_status,
                                          product: product )}


  let(:shop_enrollment_verification) { RuleSet::HbxEnrollment::IndividualMarketVerification.new(shop_enrollment) }
  let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
  let(:hired_on) { TimeKeeper.date_of_record - 3.months }
  let(:employee_created_at) { hired_on }
  let(:employee_updated_at) { employee_created_at }
  let(:shop_family) {FactoryBot.create(:family, :with_primary_family_member)}
  let(:census_employee) do
    create(:census_employee,
           :with_active_assignment,
           benefit_sponsorship: benefit_sponsorship,
           employer_profile: benefit_sponsorship.profile,
           benefit_group: current_benefit_package,
           hired_on: hired_on,
           created_at: employee_created_at,
           updated_at: employee_updated_at)
  end
  let(:employee_role) { FactoryBot.create(:employee_role, benefit_sponsors_employer_profile_id: abc_profile.id, hired_on: census_employee.hired_on, census_employee_id: census_employee.id) }
  let(:shop_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      household: shop_family.latest_household,
                      aasm_state: 'coverage_selected',
                      coverage_kind: 'health',
                      family: shop_family,
                      effective_on: current_effective_date,
                      enrollment_kind: 'open_enrollment',
                      kind: 'employer_sponsored',
                      submitted_at: effective_on - 10.days,
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: employee_role.id,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id)
  end

  describe "for a shop policy" do
    it "should not be applicable" do
      expect(shop_enrollment_verification.applicable?).to eq false
    end
  end

  describe "for an inactive individual policy" do
    let(:enrollment_status) { 'shopping' }
    it "should not be applicable" do
      expect(subject.applicable?).to eq false
    end
  end

  describe "for an active individual policy" do
    let(:enrollment_members) { [] }
    before(:each) do
      allow(enrollment).to receive(:hbx_enrollment_members).and_return(enrollment_members)
    end
    it "should be applicable" do
      expect(subject.applicable?).to eq true
    end
  end

  describe "determine the next state" do
    verification_states = %w(unverified ssa_pending dhs_pending verification_outstanding fully_verified verification_period_ended)
    verification_states.each do |state|
      obj=(state+"_person").to_sym
      let(obj) {
        person = FactoryBot.create(:person, :with_consumer_role)
        person.consumer_role.aasm_state = state
        person
      }
    end

    context "assigns proper states for people" do
      verification_states.each do |status|
        it "#{status}_person has #{status} aasm_state" do
          expect(eval("#{status}_person").consumer_role.aasm_state).to eq status
        end
      end
    end

    context "enrollment with fully verified member and status is_any_enrollment_member_outstanding false" do
      let(:enrollment_status) { 'coverage_selected' }
      let(:is_any_enrollment_member_outstanding) { false }

      it "return move_to_enrolled! event" do
        allow(subject).to receive(:roles_for_determination).and_return([fully_verified_person.consumer_role])
        expect(subject.determine_next_state).to eq [false, :do_nothing]
      end
    end

    context "enrollment with fully verified member and status not pending and is_any_enrollment_member_outstanding false" do
      let(:enrollment_status) { 'coverage_selected' }
      let(:is_any_enrollment_member_outstanding) { false }
      
      it 'should return do_nothing' do
        allow(subject).to receive(:roles_for_determination).and_return([fully_verified_person.consumer_role])
        expect(subject.determine_next_state).to eq [false, :do_nothing]
      end 
    end

    context "enrollment with outstanding member" do
      let(:enrollment_status) { 'coverage_selected' }
      it "return move_to_enrolled! event along with true value" do
        allow(subject).to receive(:roles_for_determination).and_return([verification_outstanding_person.consumer_role])
        expect(subject.determine_next_state).to eq [true, :do_nothing]
      end
    end

    context "selected enrollment with outstanding member" do
      let(:enrollment_status) { 'coverage_selected' }
      it "return move_to_enrolled! event along with true value" do
        allow(subject).to receive(:roles_for_determination).and_return([verification_outstanding_person.consumer_role])
        expect(subject.determine_next_state).to eq [true, :do_nothing]
      end
    end

    context "enrollment with verification_period_ended member" do
      it "return move_to_enrolled! event along with true value" do
        allow(subject).to receive(:roles_for_determination).and_return([verification_period_ended_person.consumer_role])
        expect(subject.determine_next_state).to eq [true, :do_nothing]
      end
    end

    context "enrollment with pending member" do
      it "return move_to_pending! event" do
        allow(subject).to receive(:roles_for_determination).and_return([ssa_pending_person.consumer_role])
        expect(subject.determine_next_state).to eq [false,:move_to_pending!]
      end
    end

    context "enrollment with mixed and outstanding members" do
      let(:enrollment_status) { 'unverified' }
      it "return move_to_enrolled! event along with true value" do
        allow(subject).to receive(:roles_for_determination).and_return([verification_outstanding_person.consumer_role, fully_verified_person.consumer_role, ssa_pending_person.consumer_role])
        expect(subject.determine_next_state).to eq [true, :move_to_enrolled!]
      end
    end

    context "enrollment with mixed, NO outstanding, with pending members" do
      it "return move_to_pending! event" do
        allow(subject).to receive(:roles_for_determination).and_return([ssa_pending_person.consumer_role, fully_verified_person.consumer_role, dhs_pending_person.consumer_role])
        expect(subject.determine_next_state).to eq [false,:move_to_pending!]
      end
    end
  end
end