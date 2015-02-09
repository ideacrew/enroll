require 'rails_helper'
require 'factories/enrollment_factory'

RSpec.describe EnrollmentFactory do
  let(:employer) {FactoryGirl.create(:employer)}
  let(:broker) {FactoryGirl.create(:broker)}
  let(:employee_family) {FactoryGirl.create(:employer_census_employee_family)}
  let(:person) {FactoryGirl.build(:person)}
  let(:new_mailing_address) do
    {
      kind: 'home',
      address_1: 1111,
      address_2: 111,
      city: 'Washington',
      state: 'DC',
      zip: 11111
    }
  end
  let(:ssn) {"123456789"}
  let(:gender) {"male"}
  let(:dob) {"01/01/1970"}
  let(:hired_on) {"01/01/2014"}
  let(:valid_params) do
    { person: person,
      employer: employer,
      ssn: ssn,
      gender: gender,
      dob: dob,
      hired_on: hired_on
    }
  end
  
  let(:npn) {"xyz123xyz"}
  let(:broker_kind) {"broker"}
  let(:valid_broker_params) do
    { person: person,
      new_npn: npn,
      new_kind: broker_kind,
      new_mailing_address: new_mailing_address
    }
  end

  describe ".add_employee_role" do
    context "with no arguments" do
      let(:params) {{}}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no person" do
      let(:params) {valid_params.except(:person)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no employer" do
      let(:params) {valid_params.except(:employer)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no date of hire" do
      let(:params) {valid_params.except(:hired_on)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no date of birth" do
      let(:params) {valid_params.except(:dob)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no gender" do
      let(:params) {valid_params.except(:gender)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no ssn" do
      let(:params) {valid_params.except(:ssn)}
      it "should raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with all required data" do
      let(:params) {valid_params}
      it "should not raise" do
        expect{EnrollmentFactory.add_employee_role(**params)}.not_to raise_error
      end
    end

  end
  
  describe ".add_broker_role" do
    context "with no arguments" do
      let(:params) {{}}
      it "should raise" do
        expect{EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end
    
    context "with all required data" do
      let(:params) {valid_broker_params}
      it "should not raise" do
        expect{EnrollmentFactory.add_broker_role(**params)}.not_to raise_error
      end
    end
    
     context "with no npn" do
      let(:params) {valid_broker_params.except(:new_npn)}
      it "should raise" do
        expect{EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end
  end
end
