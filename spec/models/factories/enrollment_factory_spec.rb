require 'rails_helper'
require 'factories/enrollment_factory'

RSpec.describe EnrollmentFactory do
  let(:employer) {FactoryGirl.create(:employer_profile)}
  let(:employee_family) {FactoryGirl.create(:employer_census_family, employer: employer)}
  let(:person) {FactoryGirl.create(:person)}
  let(:ssn) {"123456789"}
  let(:dob) {"01/01/1970"}
  let(:gender) {"male"}

  describe ".add_employee_role" do
    let(:hired_on) {"01/01/2014"}
    let(:valid_params) do
      { person: person,
        employer_census_family: employee_family,
        ssn: ssn,
        gender: gender,
        dob: dob,
        hired_on: hired_on
      }
    end

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
      let(:params) {valid_params.except(:employer_census_family)}

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

      context "successfully created" do
        let(:employee) {EnrollmentFactory.add_employee_role(**params)}
        let(:family) {employee.person.family}
        let(:primary_applicant) {family.primary_applicant}
        let(:employer_census_family) do
          Employer.find(employer).employee_families.find(employee_family)
        end

        it "should have a family" do
          expect(family.class).to be Family
        end

        it "should be the primary applicant" do
          expect(employee.person).to eq primary_applicant.person
        end

        it "should have linked the family" do
          
          expect(employee_family.linked_employee).to eq employee
        end
      end
    end


  end

  describe ".add_consumer_role" do
    let(:is_incarcerated) {true}
    let(:is_applicant) {true}
    let(:is_state_resident) {true}
    let(:citizen_status) {"us_citizen"}

    let(:valid_params) do
      { person: person,
        new_is_incarcerated: is_incarcerated,
        new_is_applicant: is_applicant,
        new_is_state_resident: is_state_resident,
        new_ssn: ssn,
        new_dob: dob,
        new_gender: gender,
        new_citizen_status: citizen_status
      }
    end

    context "with no arguments" do
      let(:params) {{}}
      it "should raise" do
        expect{EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

   context "with no is_incarcerated" do
      let(:params) {valid_params.except(:new_is_incarcerated)}
      it "should raise" do
        expect{EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
   end

   context "with no is_applicant" do
      let(:params) {valid_params.except(:new_is_applicant)}
      it "should raise" do
        expect{EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
   end

   context "with no is_state_resident" do
      let(:params) {valid_params.except(:new_is_state_resident)}
      it "should raise" do
        expect{EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
   end

   context "with no citizen_status" do
      let(:params) {valid_params.except(:new_citizen_status)}
      it "should raise" do
        expect{EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
   end

   context "with all required data" do
      let(:params) {valid_params}
      it "should not raise" do
        expect{EnrollmentFactory.add_consumer_role(**params)}.not_to raise_error
      end
    end

  end


  describe ".add_broker_role" do
    let(:mailing_address) do
      {
        kind: 'home',
        address_1: 1111,
        address_2: 111,
        city: 'Washington',
        state: 'DC',
        zip: 11111
      }
    end

    let(:npn) {"xyz123xyz"}
    let(:broker_kind) {"broker"}
    let(:valid_params) do
      { person: person,
        new_npn: npn,
        new_kind: broker_kind,
        new_mailing_address: mailing_address
      }
    end

    context "with no arguments" do
      let(:params) {{}}
      it "should raise" do
        expect{EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with all required data" do
      let(:params) {valid_params}
      it "should not raise" do
        expect{EnrollmentFactory.add_broker_role(**params)}.not_to raise_error
      end
    end

    context "with no npn" do
      let(:params) {valid_params.except(:new_npn)}
      it "should raise" do
        expect{EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no kind" do
      let(:params) {valid_params.except(:new_kind)}
      it "should raise" do
        expect{EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no mailing address" do
      let(:params) {valid_params.except(:new_mailing_address)}
      it "should raise" do
        expect{EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

  end
end
