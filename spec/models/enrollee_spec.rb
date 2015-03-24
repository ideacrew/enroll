require 'rails_helper'

RSpec.describe Enrollee, :type => :model do
  context "validation" do
    it { should validate_presence_of :person_id }
    it { should validate_presence_of :coverage_start_on }
  end

  let(:premium_table_1){PremiumTable.new(age: 42, start_on: "2015-01-01", end_on: "2015-12-31", cost: "198.42" )}
  let(:premium_table_2){PremiumTable.new(age: 43, start_on: "2015-01-01", end_on: "2015-12-31", cost: "200.42" )}
  let(:premium_table_3){PremiumTable.new(age: 42, start_on: "2015-08-01", end_on: "2015-12-31", cost: "198.41" )}
  let(:plan) {Plan.new(name: "KP DC Gold 0/20/Dental", premium_tables: [premium_table_1, premium_table_2, premium_table_3] )}
  let(:policy) {Policy.new(hbx_id: "100009", plan_id: plan, effective_on: "2015-01-04")}
  let(:person) {FactoryGirl.create(:person)}
  let(:valid_params) do
    {
      coverage_start_on: "2015-01-04",
      person_id: person.id,
      policy: policy
    }
  end
  let(:invalid_params) {{coverage_start_on: "2015-01-04", policy: policy}}

  context "person" do
    let(:enrollee) { Enrollee.new(**valid_params) }

    it "should equal person" do
      expect(enrollee.person).to eq person
    end

    it "should raise error with nil person" do
      expect{enrollee.person = nil}.to raise_error
    end
  end

  describe "set_premium" do
    let(:enrollee) { Enrollee.new(**valid_params) } 

    it "return nil while policy.plan is blank" do 
      policy.set(plan_id: nil)
      expect(enrollee.set_premium).to eq nil
    end

    it "return nil while coverage_start_age is blank" do
      enrollee.set(person_id: nil)
      expect(enrollee.set_premium).to eq nil 
    end 
  end

  describe "parent" do
    let(:enrollee) { Enrollee.new(**valid_params.merge(policy: nil)) }

    it "should raise error with nil policy" do
      expect{ enrollee.parent }.to raise_error
    end
  end

  describe "coverage_start_age" do
    let(:enrollee) { Enrollee.new(**valid_params) }

    it "return nil while person is blank" do 
      enrollee.update(person_id: nil)
      expect(enrollee.coverage_start_age).to eq nil
    end

    it "return nil while parent.effective_on is blank" do
      policy.update(effective_on: nil)
      expect(enrollee.coverage_start_age).to eq nil 
    end 

    context "when coverage start month equal person month" do
      let(:date) { Date.today }
      let(:age) { enrollee.coverage_start_on.year - person.dob.year } 

      it "minor age when day is less than person's" do
        enrollee.set(coverage_start_on: (date - 1.days))
        person.set(dob: date)
        expect(enrollee.coverage_start_age).to eq (age - 1)
      end 

      it "not minor age when day is not less than person's" do
        enrollee.set(coverage_start_on: date)
        person.set(dob: date)
        expect(enrollee.coverage_start_age).to eq age
      end
    end

    context "when coverage start month not equal person month" do
      let(:date) { Date.today }
      let(:age) { enrollee.coverage_start_on.year - person.dob.year }

      it "minor age when day is less than person's" do
        enrollee.set(coverage_start_on: date - 1.month)
        person.set(dob: date)
        expect(enrollee.coverage_start_age).to eq (age - 1)
      end 

      it "not minor age when day is not less than person's" do
        enrollee.set(coverage_start_on: date + 1.month)
        person.set(dob: date)
        expect(enrollee.coverage_start_age).to eq age
      end 
    end 
  end

  describe "calculate premium" do
    context "should return " do
      let(:params) {valid_params}
      it "correct dollar amount" do
        enrollee = Enrollee.new(**params)
        expect(enrollee.calculate_premium.cost).to eq 198.42
      end
    end
  end
end
