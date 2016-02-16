require "rails_helper"

RSpec.describe Insured::FamiliesHelper, :type => :helper do
  describe "#generate_options_for_effective_on_kinds" do
    it "it should return blank array" do
      options = helper.generate_options_for_effective_on_kinds([], TimeKeeper.date_of_record)
      expect(options).to eq []
    end

    it "it should return options" do
      options = helper.generate_options_for_effective_on_kinds(['date_of_event', 'fixed_first_of_next_month'], TimeKeeper.date_of_record)
      date = TimeKeeper.date_of_record
      expect(options).to eq [[date.to_s, 'date_of_event'], [(date.end_of_month+1.day).to_s, 'fixed_first_of_next_month']]
    end
  end

  describe "#show_employer_panel" do
    let(:person) {FactoryGirl.build(:person)}
    let(:employee_role) {FactoryGirl.build(:employee_role)}
    let(:census_employee) {FactoryGirl.build(:census_employee)}
    let(:person_with_employee_role) {FactoryGirl.create(:person, :with_employee_role)}
    let(:benefit_group_assignment) {BenefitGroupAssignment.new()}

    it "should return false without person" do
      expect(helper.show_employer_panel?(nil)).to eq false
    end

    it "should return false with person who has no active employee_role" do
      allow(person).to receive(:has_active_employee_role?).and_return false
      expect(helper.show_employer_panel?(person)).to eq false
    end

    context "with person who has active_employee_roles" do
      before :each do
        allow(person).to receive(:has_active_employee_role?).and_return true
        allow(person).to receive(:active_employee_roles).and_return [employee_role]
        allow(employee_role).to receive(:census_employee).and_return census_employee
      end

      it "should return false when employee_role has active benefit group assignment" do
        allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
        allow(benefit_group_assignment).to receive(:initialized?).and_return false
        expect(helper.show_employer_panel?(person)).to eq false
      end

      context "when employee_role has active benefit_group_assignment which is not initialized" do
        before do
          allow(census_employee).to receive(:active_benefit_group_assignment).and_return benefit_group_assignment
          allow(benefit_group_assignment).to receive(:initialized?).and_return true
        end

        it "should return false" do
          expect(helper.show_employer_panel?(person)).to eq false
        end
      end
    end
  end
end
