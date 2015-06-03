require 'rails_helper'

RSpec.describe CensusEmployee, type: :model, dbclean: :after_each do
  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :hired_on }
  it { should validate_presence_of :is_business_owner }
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
  let(:is_business_owner){ false }
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
      is_business_owner: is_business_owner,
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
      let(:params) {valid_params.except(:is_business_owner)}

    it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:is_business_owner].any?).to be_truthy
      end
    end

    context "with all required data" do
      let(:params) { valid_params }
      let(:census_employee)         { CensusEmployee.new(**params) }
      let(:valid_employee_role)     { FactoryGirl.create(:employee_role, ssn: census_employee.ssn, dob: census_employee.dob) }
      let(:invalid_employee_role)   { FactoryGirl.create(:employee_role, ssn: "777777777", dob: Date.current - 5.days) }

      it "should save" do
        expect(census_employee.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_census_employee) do
          ee = CensusEmployee.new(**params)
          ee.save
          ee
        end

        it "should be findable by ID" do
          expect(CensusEmployee.find(saved_census_employee._id)).to eq saved_census_employee
        end

        it "in an unlinked state" do
          expect(saved_census_employee.employee_role_unlinked?).to be_truthy
        end

        it "and should have the correct associated employer profile" do
          expect(saved_census_employee.employer_profile._id).to eq census_employee.employer_profile_id
        end

        it "should be findable by employer profile" do
          expect(CensusEmployee.find_all_by_employer_profile(employer_profile).size).to eq 1
          expect(CensusEmployee.find_all_by_employer_profile(employer_profile).first).to eq saved_census_employee
        end


        context "and a roster search is performed" do
          context "using an ssn and dob without a matching roster instance" do
            it "should return nil" do
              expect(CensusEmployee.find_all_unlinked_by_identifying_information(invalid_employee_role.ssn, invalid_employee_role.dob)).to eq []
            end
          end

          context "using an ssn and dob with a matching roster instance" do
            it "should return the roster instance" do
              expect(CensusEmployee.find_all_unlinked_by_identifying_information(valid_employee_role.ssn, valid_employee_role.dob)).to eq [saved_census_employee]
            end
          end
        end

        context "and a link employee role request is made" do
          it "the roster instance should be in a state ready for linking" do
            expect(saved_census_employee.may_link_employee_role?).to be_truthy
          end

          context "and the provided employee role identifying information doesn't match a census employee" do
            it "should raise an error" do
              expect{saved_census_employee.employee_role = invalid_employee_role}.to raise_error(CensusEmployeeError)
            end
          end

          context "and the provided employee role identifying information does match a census employee" do
            before { saved_census_employee.employee_role = valid_employee_role }

            it "should link the roster instance and employer role" do
              expect(saved_census_employee.employee_role_linked?).to be_truthy
            end

            context "and it is saved" do
              before { saved_census_employee.save }
              it "should no longer be available for linking" do
                expect(saved_census_employee.may_link_employee_role?).to be_falsey 
              end

              it "should be findable by employee role" do
                expect(CensusEmployee.find_all_by_employee_role(valid_employee_role).size).to eq 1
                expect(CensusEmployee.find_all_by_employee_role(valid_employee_role).first).to eq saved_census_employee
              end

              it "and should be delinkable" do
                expect(saved_census_employee.may_delink_employee_role?).to be_truthy
              end
            end

            context "and employee is terminated" do
              let(:invalid_termination_date)  { (Date.current - HbxProfile::ShopRetroactiveTerminationMaximum).beginning_of_month - 1.day }
              let(:valid_termination_date)    { Date.current - HbxProfile::ShopRetroactiveTerminationMaximum }

              context "and the termination date exceeds the HBX maximum" do
                context "and the user is employer rep" do

                  it "transition to terminated state should be valid" do
                    expect(saved_census_employee.may_terminate?).to be_truthy
                  end

                  it "should prohibit termination" do
                    expect{saved_census_employee.terminate_employment!(invalid_termination_date)}.to raise_error CensusEmployeeError
                  end
                end
                context "and the user is HBX admin" do
                  it "transition to terminated state should be valid" do
                    expect(saved_census_employee.may_terminate?).to be_truthy
                  end

                  it "should permit termination" do
                    expect(saved_census_employee.terminate_employment(valid_termination_date).employment_terminated_on).to eq valid_termination_date
                  end
                end
              end

              context "and the termination date is within the HBX maximum" do
                it "transition to terminated state should be valid" do
                  expect(saved_census_employee.may_terminate?).to be_truthy
                end

                it "should permit termination"
              end
            end
          end

          context "and the roster census employee instance is in any state besides unlinked" do
            let(:employee_role_linked_state)  { saved_census_employee.dup }
            let(:employment_terminated_state)  { saved_census_employee.dup }
            before do
              employee_role_linked_state.aasm_state = :employee_role_linked
              employment_terminated_state.aasm_state = :employment_terminated
            end

            it "should prevent linking with another employee role" do
              expect(employee_role_linked_state.may_link_employee_role?).to be_falsey 
              expect(employment_terminated_state.may_link_employee_role?).to be_falsey 
            end
          end
        end
      end
    end
  end
end
