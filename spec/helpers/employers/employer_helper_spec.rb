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

    context ".enrollment_state" do

      context 'when enrollments not present' do 

        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([]) 
        end

        it "should return initialized as default" do
          expect(helper.enrollment_state(census_employee)).to be_blank
        end
      end

      context 'when health coverage present' do 
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment]) 
        end

        it "should return health enrollment status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Health)"
        end
      end

      context 'when dental coverage present' do 
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([dental_enrollment]) 
        end

        it "should return dental enrollment status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Dental)"
        end
      end

      context 'when both health & dental coverage present' do 
        before do
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment, dental_enrollment]) 
        end

        it "should return enrollment status for both health & dental" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Selected (Health), Coverage Selected (Dental)"
        end
      end

      context 'when coverage terminated' do 
        before do
          health_enrollment.terminate_coverage!
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment]) 
        end

        it "should return terminated status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Terminated (Health)"
        end
      end

      context 'when coverage waived' do 
        before do
          health_enrollment.update_attributes(:aasm_state => :inactive)
          allow(benefit_group_assignment).to receive(:hbx_enrollments).and_return([health_enrollment]) 
        end

        it "should return terminated status" do
          expect(helper.enrollment_state(census_employee)).to eq "Coverage Waived (Health)"
        end
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
