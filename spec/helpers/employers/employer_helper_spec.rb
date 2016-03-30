require "rails_helper"

RSpec.describe Employers::EmployerHelper, :type => :helper do
  describe "#enrollment_state" do

    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:census_employee) { FactoryGirl.create(:census_employee, employee_role_id: employee_role.id) }
    let(:benefit_group_assignment) { double }
    let(:person) {double}
    let(:primary_family) { FactoryGirl.create(:family, :with_primary_family_member) }
    let(:dental_plan) { FactoryGirl.create(:plan, coverage_kind: "dental", dental_level: "high" ) }
    let(:health_plan) { FactoryGirl.create(:plan, coverage_kind: "health") }
    let(:dental_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                              household: primary_family.latest_household,
                                              employee_role_id: employee_role.id,
                                              coverage_kind: 'dental',
                                              plan: dental_plan
                                            )}
    let(:health_enrollment)   { FactoryGirl.create( :hbx_enrollment,
                                              household: primary_family.latest_household,
                                              employee_role_id: employee_role.id,
                                              plan: health_plan
                                            )}

    before do
      allow(benefit_group_assignment).to receive(:aasm_state).and_return("coverage_selected")
      allow(census_employee).to receive(:employee_role).and_return(employee_role)
      allow(census_employee).to receive(:active_benefit_group_assignment).and_return(benefit_group_assignment)
      allow(employee_role).to receive(:person).and_return(person)
      allow(person).to receive(:primary_family).and_return(primary_family)
    end

    context "return enrollment state for census_employee" do

      it "with nil" do
        expect(helper.enrollment_state()).to eq ""
      end

      it "when aasm_state is initialized" do
        allow(benefit_group_assignment).to receive(:aasm_state).and_return("initialized")
        expect(helper.enrollment_state(census_employee)).to eq ""
      end

      it "when aasm_state is coverage_selected and of type Health" do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([health_enrollment])
        expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Health)"
      end

      it "when aasm_state is coverage_selected and of type Dental" do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([dental_enrollment])
        expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Dental)"
      end

      # Tests the uniqueness
      it "when there are two plans with state coverage selected and both type dental, should return only one" do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([dental_enrollment, dental_enrollment])
        expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Dental)"
      end

      # Tests the uniqueness
      it "when there are two plans with state coverage selected and both type health, should return only one" do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([health_enrollment, health_enrollment])
        expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Health)"
      end

    end


    context "return coverage kind for a census_employee" do


      it " when coverage kind is nil " do
        expect(helper.coverage_kind(nil)).to eq ""
      end

      it " when coverage kind is 'health' " do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([health_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Health"
      end

      it " when coverage kind is 'dental' " do
        allow(primary_family).to receive(:enrolled_hbx_enrollments).and_return([dental_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Dental"
      end

      # Tests the sort and reverse. Always want 'Health' before 'Dental'
      it " when coverage kind is 'health, dental' " do
        allow(primary_family).to receive(:enrolled_including_waived_hbx_enrollments).and_return([health_enrollment, dental_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Health, Dental"
      end

      # Tests the sort and reverse. Always want 'Health' before 'Dental'
      it " when coverage kind is 'dental, health' " do
        allow(primary_family).to receive(:enrolled_including_waived_hbx_enrollments).and_return([dental_enrollment, health_enrollment])
        expect(helper.coverage_kind(census_employee)).to eq "Health, Dental"
      end


    end


  end
end
