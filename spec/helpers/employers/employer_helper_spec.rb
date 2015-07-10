require "rails_helper"

RSpec.describe Employers::EmployerHelper, :type => :helper do
  describe "#enrollment_state" do

    context "return enrollment state by census_employee" do
      let(:census_employee) { double(active_benefit_group_assignment: benefit_group_assignment) }
      let(:benefit_group_assignment) { double }

      it "with nil" do
        expect(helper.enrollment_state()).to eq ""
      end

      it "when aasm_state is initialized" do
        allow(benefit_group_assignment).to receive(:aasm_state).and_return("initialized")
        expect(helper.enrollment_state(census_employee)).to eq ""
      end

      it "when aasm_state is coverage_selected" do
        allow(benefit_group_assignment).to receive(:aasm_state).and_return("coverage_selected")
        expect(helper.enrollment_state(census_employee)).to eq "Coverage selected"
      end

      it "when aasm_state is coverage_terminated" do
        allow(benefit_group_assignment).to receive(:aasm_state).and_return("coverage_terminated")
        expect(helper.enrollment_state(census_employee)).to eq "Coverage terminated"
      end

      it "when aasm_state is coverage_waived" do
        allow(benefit_group_assignment).to receive(:aasm_state).and_return("coverage_waived")
        expect(helper.enrollment_state(census_employee)).to eq "Coverage waived"
      end
    end
  end
end
