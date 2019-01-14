require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_initial_plan_year_aasm_state")


describe ChangeInitialPlanYearAasmState, dbclean: :after_each do

  let(:given_task_name) { "change_initial_plan_year_aasm_state" }
  subject { ChangeInitialPlanYearAasmState.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating aasm_state of the initial plan year", dbclean: :after_each do
    let(:start_on)      { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
    let(:benefit_group) { FactoryBot.create(:benefit_group) }
    let!(:canceled_plan_year){ FactoryBot.build(:plan_year,start_on: start_on, aasm_state: "canceled", open_enrollment_start_on: TimeKeeper.date_of_record, benefit_groups:[benefit_group]) }
    let!(:employer_profile){ FactoryBot.create(:employer_profile, aasm_state:'applicant',plan_years: [canceled_plan_year], organization: organization) }
    let!(:organization)  { FactoryBot.create(:organization) }
    let(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:census_employee) { FactoryBot.create(:census_employee,employer_profile: employer_profile,:benefit_group_assignments => [benefit_group_assignment]) }
    let!(:employer_attestation) { FactoryBot.create(:employer_attestation,aasm_state:'approved',employer_profile:employer_profile) }
    let!(:document) { FactoryBot.create(:employer_attestation_document, aasm_state: 'accepted', employer_attestation: employer_attestation) }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(start_on)
      allow(ShopNoticesNotifierJob).to receive(:perform_later).and_return true
      allow(ENV).to receive(:[]).with("py_state").and_return('')
    end

    it "should update aasm_state of plan year" do
      expect(canceled_plan_year.aasm_state).to eq "canceled"  # before migration
      subject.migrate
      canceled_plan_year.reload
      expect(canceled_plan_year.aasm_state).to eq "enrolling"  # after migration
    end

    it "should not update active plan year" do
      canceled_plan_year.update_attributes(aasm_state:'active') # before migration
      subject.migrate
      canceled_plan_year.reload
      expect(canceled_plan_year.aasm_state).to eq "active" # after migration
    end

    it "should update plan year aasm state of plan year after force publish date" do
      canceled_plan_year.update_attributes(aasm_state:'application_ineligible') # before migration
      subject.migrate
      canceled_plan_year.reload
      canceled_plan_year.employer_profile.reload
      expect(canceled_plan_year.aasm_state).to eq "enrolling" # after migration
    end
  end

  describe "updating aasm_state for plan year", dbclean: :after_each do
    let(:start_on)      { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
    let(:benefit_group) { FactoryBot.create(:benefit_group) }
    let!(:plan_year){ FactoryBot.build(:plan_year,start_on: start_on,benefit_groups:[benefit_group]) }
    let!(:employer_profile){ FactoryBot.build(:employer_profile, aasm_state:'binder_paid',plan_years: [plan_year]) }
    let!(:organization)  {FactoryBot.create(:organization, employer_profile:employer_profile)}
    let(:benefit_group_assignment) { FactoryBot.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let(:census_employee) { FactoryBot.create(:census_employee,employer_profile: employer_profile,:benefit_group_assignments => [benefit_group_assignment]) }
    let!(:employer_attestation) { FactoryBot.create(:employer_attestation,aasm_state:'approved',employer_profile:employer_profile) }
    let!(:document) { FactoryBot.create(:employer_attestation_document, aasm_state: 'accepted', employer_attestation: employer_attestation) }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(start_on)
      allow(ENV).to receive(:[]).with("py_state").and_return('enrolled')
    end

    it "should update aasm_state of plan year" do
      allow_any_instance_of(PlanYear).to receive(:is_enrollment_valid?).and_return(false)
      expect(plan_year.valid?).to be_truthy
      subject.migrate
      plan_year.reload
      plan_year.employer_profile.reload
      expect(plan_year.aasm_state).to eq "enrolled"
    end
  end
end
