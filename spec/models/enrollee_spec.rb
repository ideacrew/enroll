require 'rails_helper'

RSpec.describe Enrollee, :type => :model do
  it { should validate_presence_of :person_id }
  it { should validate_presence_of :coverage_start_on }

  let(:premium_table_1){PremiumTable.new(age: 42, start_on: "2015-01-01", end_on: "2015-12-31", cost: "198.42" )}
  let(:premium_table_2){PremiumTable.new(age: 43, start_on: "2015-01-01", end_on: "2015-12-31", cost: "200.42" )}
  let(:premium_table_3){PremiumTable.new(age: 42, start_on: "2015-08-01", end_on: "2015-12-31", cost: "198.41" )}
  let(:plan) {Plan.new(name: "KP DC Gold 0/20/Dental", premium_tables: [premium_table_1, premium_table_2, premium_table_3] )}
  let(:policy) {Policy.new(hbx_id: "100009", plan_id: plan, effective_on: "2015-01-04")}
  let(:person) {FactoryGirl.create(:person)}


  describe "calculate premium" do
    let(:valid_params) do
      {
        coverage_start_on: "2015-01-04",
        person_id: person.id,
        policy: policy
      }
    end

    context "should return " do
      let(:params) {valid_params}
      it "correct dollar amount" do
        enrollee = Enrollee.new(**params)
        expect(enrollee.calculate_premium.cost).to eq 198.42
      end
    end
  end

end
