require 'rails_helper'

RSpec.describe CensusEmployee, :type => :model do
  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :hired_on }
  it { should validate_presence_of :is_owner }
  it { should validate_presence_of :employer_profile_id }

  let(:employer_profile) { FactoryGirl.build(:employer_profile) }

  let(:first_name){ "Lynyrd" }
  let(:middle_name){ "Rattlesnake" }
  let(:last_name){ "Skynyrd" }
  let(:name_sfx){ "PhD" }
  let(:ssn){ "230987654" }
  let(:dob){ Date.today - 31.years }
  let(:gender){ "male" }
  let(:hired_on){ Date.current - 14.days }
  let(:is_owner){ false }
  let(:address) { Address.new(kind: "home", address_1: "221 R St, NW", city: "Washington", state: "DC", zip: "20001") }

  let(:valid_params){
    {
      employer_profile: employer_profile,
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name,
      name_sfx: name_sfx,
      ssn: ssn,
      dob: dob,
      gender: gender,
      hired_on: hired_on,
      is_owner: is_owner,
      address: address
    }
  }

  describe ".new" do

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(CensusEmployee.create(**params).valid?).to be_falsey
      end
    end

    context "with no employer_profile" do
      let(:params) {valid_params.except(:employer_profile)}

    it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:employer_profile_id].any?).to be_truthy
      end
    end

    context "with no ssn" do
      let(:params) {valid_params.except(:ssn)}

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:ssn].any?).to be_truthy
      end
    end

    context "with no dob" do
      let(:params) {valid_params.except(:dob)}

    it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:dob].any?).to be_truthy
      end
    end

    context "with no hired_on" do
      let(:params) {valid_params.except(:hired_on)}

    it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:hired_on].any?).to be_truthy
      end
    end

    context "with no is owner" do
      let(:params) {valid_params.except(:is_owner)}

    it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:is_owner].any?).to be_truthy
      end
    end

    context "with all required data" do
      let(:params) {valid_params}
      let(:census_employee) {CensusEmployee.new(**params)}

      it "should save" do
        expect(census_employee.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_census_employee) do
          ee = CensusEmployee.new(**params)
          ee.save
          ee
        end

        it "and should be findable" do
          expect(CensusEmployee.find(saved_census_employee._id)).to eq saved_census_employee
          # expect(CensusEmployee.last).to eq saved_census_employee.inspect
        end

      end
    end
  end


end
