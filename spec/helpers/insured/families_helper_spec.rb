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

    it "should return false without employee_role" do
      expect(helper.newhire_enrollment_eligible?(nil)).to eq false
    end

    it "should return false with employee_role who has no census_employee" do
      allow(employee_role).to receive(:census_employee).and_return nil
      expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
    end

    context "with employee_role who has census_employee" do
      before :each do
        allow(employee_role).to receive(:census_employee).and_return census_employee
      end

      it "should return false when census_employee is not newhire_enrollment_eligible" do
        allow(census_employee).to receive(:newhire_enrollment_eligible?).and_return false
        expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
      end

      context "when census_employee is newhire_enrollment_eligible" do
        before do
          allow(census_employee).to receive(:newhire_enrollment_eligible?).and_return true
        end

        it "should return false when person can not select coverage" do
          allow(employee_role).to receive(:can_select_coverage?).and_return false
          expect(helper.newhire_enrollment_eligible?(employee_role)).to eq false
        end

        it "should return true when person can select coverage" do
          allow(employee_role).to receive(:can_select_coverage?).and_return true
          expect(helper.newhire_enrollment_eligible?(employee_role)).to eq true
        end
      end
    end
  end
end
