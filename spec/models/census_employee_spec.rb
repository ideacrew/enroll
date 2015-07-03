require 'rails_helper'

RSpec.describe CensusEmployee, type: :model, dbclean: :after_each do
  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :hired_on }
  it { should validate_presence_of :is_business_owner }
  it { should validate_presence_of :employer_profile_id }

  let(:benefit_group)    { FactoryGirl.create(:benefit_group) }
  let(:plan_year)        { benefit_group.plan_year }
  let(:employer_profile) { plan_year.employer_profile }

  let(:first_name){ "Lynyrd" }
  let(:middle_name){ "Rattlesnake" }
  let(:last_name){ "Skynyrd" }
  let(:name_sfx){ "PhD" }
  let(:ssn){ "230987654" }
  let(:dob){ Date.today - 31.years }
  let(:gender){ "male" }
  let(:hired_on){ TimeKeeper.date_of_record - 14.days }
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

  describe "a new instance" do
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
      let(:params) { valid_params.merge({:is_business_owner => nil}) }

      it "should fail validation" do
        expect(CensusEmployee.create(**params).errors[:is_business_owner].any?).to be_truthy
      end
    end

    context "with all required attributes" do
      let(:params)                  { valid_params }
      let(:initial_census_employee) { CensusEmployee.new(**params) }

      it "should be valid" do
        expect(initial_census_employee.valid?).to be_truthy
      end

      it "should save" do
        expect(initial_census_employee.save).to be_truthy
      end

      context "and it is saved" do
        before { initial_census_employee.save }

        it "should be findable by ID" do
          expect(CensusEmployee.find(initial_census_employee.id)).to eq initial_census_employee
        end

        it "in an unlinked state" do
          expect(initial_census_employee.eligible?).to be_truthy
        end

        it "and should have the correct associated employer profile" do
          expect(initial_census_employee.employer_profile._id).to eq initial_census_employee.employer_profile_id
        end

        it "should be findable by employer profile" do
          expect(CensusEmployee.find_all_by_employer_profile(employer_profile).size).to eq 1
          expect(CensusEmployee.find_all_by_employer_profile(employer_profile).first).to eq initial_census_employee
        end

        context "and a benefit group hasn't been assigned to employee" do
          it "the roster instance should not be ready for linking" do
            expect(initial_census_employee.may_link_employee_role?).to be_falsey
          end

          context "and the employee is assigned a benefit group" do
            let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: initial_census_employee) }

            before do
              initial_census_employee.benefit_group_assignments = [benefit_group_assignment]
              initial_census_employee.save
            end

            context "and the benefit group plan year isn't published" do
              it "the roster instance should not be ready for linking" do
                expect(initial_census_employee.may_link_employee_role?).to be_falsey
              end            
            end

            context "and the benefit group plan year is published" do
              before { plan_year.publish! }

              it "the employee census record should be ready for linking" do
                expect(initial_census_employee.may_link_employee_role?).to be_truthy
              end

              context "and a roster match by SSN and DOB is performed" do
                context "using non-matching ssn and dob" do
                  let(:invalid_employee_role)   { FactoryGirl.create(:employee_role, ssn: "777777777", dob: TimeKeeper.date_of_record - 5.days) }

                  it "should return an empty array" do
                    expect(CensusEmployee.matchable(invalid_employee_role.ssn, invalid_employee_role.dob)).to eq []
                  end
                end

                context "using matching ssn and dob" do
                  let(:valid_employee_role)     { FactoryGirl.create(:employee_role, ssn: initial_census_employee.ssn, dob: initial_census_employee.dob, employer_profile: employer_profile) }

                  it "should return the roster instance" do
                    expect(CensusEmployee.matchable(valid_employee_role.ssn, valid_employee_role.dob).collect(&:id)).to eq [initial_census_employee.id]
                  end

                  context "and a link employee role request is received" do
                    context "and the provided employee role identifying information doesn't match a census employee" do
                      let(:invalid_employee_role)   { FactoryGirl.create(:employee_role, ssn: "777777777", dob: TimeKeeper.date_of_record - 5.days) }

                      it "should raise an error" do
                        expect{initial_census_employee.employee_role = invalid_employee_role}.to raise_error(CensusEmployeeError)
                      end
                    end

                    context "and the provided employee role identifying information does match a census employee" do
                      # let(:valid_employee_role)     { FactoryGirl.create(:employee_role, ssn: initial_census_employee.ssn, dob: initial_census_employee.dob, employer_profile: employer_profile) }
                      # let(:valid_employee_role)       { employee_role }
                      before { initial_census_employee.employee_role = valid_employee_role }

                      it "should link the roster instance and employer role" do
                        expect(initial_census_employee.employee_role_linked?).to be_truthy
                      end

                      context "and it is saved" do
                        before { initial_census_employee.save }

                        it "should no longer be available for linking" do
                          expect(initial_census_employee.may_link_employee_role?).to be_falsey
                        end

                        it "should be findable by employee role" do
                          expect(CensusEmployee.find_all_by_employee_role(valid_employee_role).size).to eq 1
                          expect(CensusEmployee.find_all_by_employee_role(valid_employee_role).first).to eq initial_census_employee
                        end

                        it "and should be delinkable" do
                          expect(initial_census_employee.may_delink_employee_role?).to be_truthy
                        end

                        it "should have a published benefit group" do
                          expect(initial_census_employee.published_benefit_group).to eq benefit_group
                        end

                        context "and employee is terminated" do
                          let(:invalid_termination_date)  { (TimeKeeper.date_of_record - HbxProfile::ShopRetroactiveTerminationMaximum).beginning_of_month - 1.day }
                          let(:valid_termination_date)    { TimeKeeper.date_of_record - HbxProfile::ShopRetroactiveTerminationMaximum }

                          it "transition to termination should be valid" do
                            expect(initial_census_employee.may_terminate_employee_role?).to be_truthy
                          end

                          context "and the termination date exceeds the HBX maximum" do
                            before { initial_census_employee.terminate_employment(invalid_termination_date) }

                            context "and the user is employer rep" do
                              it "transition to terminated state should fail" do
                                expect{initial_census_employee.terminate_employment!(invalid_termination_date)}.to raise_error CensusEmployeeError
                              end
                            end

                            context "and the user is HBX admin" do
                              it "should permit termination" do
                                pending("adding cancancan authorization")
                                fail
                                # expect((initial_census_employee.terminate_employment!(valid_termination_date)).employment_terminated_on).to eq valid_termination_date
                              end
                            end
                          end

                          context "and the termination date is within the HBX maximum" do
                            before { initial_census_employee.terminate_employment!(valid_termination_date) }

                            it "is should transition to terminated state" do
                              expect(initial_census_employee.employment_terminated?).to be_truthy
                            end

                            context "and the terminated employee is rehired" do
                              let!(:rehire)   { initial_census_employee.replicate_for_rehire }

                              it "rehired census employee instance should have same demographic info" do
                                expect(rehire.first_name).to eq initial_census_employee.first_name
                                expect(rehire.last_name).to eq initial_census_employee.last_name
                                expect(rehire.gender).to eq initial_census_employee.gender
                                expect(rehire.ssn).to eq initial_census_employee.ssn
                                expect(rehire.dob).to eq initial_census_employee.dob
                                expect(rehire.employer_profile).to eq initial_census_employee.employer_profile
                              end

                              it "rehired census employee instance should be initialized state" do
                                expect(rehire.eligible?).to be_truthy
                                expect(rehire.hired_on).to_not eq initial_census_employee.hired_on
                                expect(rehire.active_benefit_group_assignment.present?).to be_falsey
                                expect(rehire.employee_role.present?).to be_falsey
                              end

                              it "the previously terminated census employee should be in rehired state" do
                                expect(initial_census_employee.aasm_state).to eq "rehired"
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
      end
    end
  end

  context "a census employee is added in the database" do
    let!(:existing_census_employee)     { CensusEmployee.create(
                                            first_name: "Paxton",
                                            last_name: "Thomas",
                                            ssn: "551345151",
                                            dob: "2014-04-01".to_date,
                                            gender: "male",
                                            employer_profile: employer_profile,
                                            hired_on: "2014-08-12".to_date
                                          )}
    let!(:person)                       { Person.create(
                                            first_name: existing_census_employee.first_name,
                                            last_name: existing_census_employee.last_name,
                                            ssn: existing_census_employee.ssn,
                                            dob: existing_census_employee.dob,
                                            gender: existing_census_employee.gender
                                          )}
    let!(:employee_role)                { EmployeeRole.create(
                                            person: person,
                                            hired_on: existing_census_employee.hired_on,
                                            employer_profile: existing_census_employee.employer_profile,
                                          )}

    it "existing record should be findable" do
      expect(CensusEmployee.find(existing_census_employee.id)).to be_truthy
    end

    context "and a new census employee instance, with same ssn same employer profile is built" do
      let!(:duplicate_census_employee)    { existing_census_employee.dup }

      it "should have same identifying info" do
        expect(duplicate_census_employee.ssn).to eq existing_census_employee.ssn
        expect(duplicate_census_employee.employer_profile_id).to eq existing_census_employee.employer_profile_id
      end

      context "and existing census employee is in eligible status" do
        it "existing record should be eligible status" do
          expect(CensusEmployee.find(existing_census_employee.id).aasm_state).to eq "eligible"
        end

        it "new instance should fail validation" do
          expect(duplicate_census_employee.valid?).to be_falsey
          expect(duplicate_census_employee.errors[:base].first).to match(/Employee with this identifying information is already active/)
        end

        context "and assign existing census employee to benefit group" do
          let(:benefit_group_assignment)  { FactoryGirl.create(:benefit_group_assignment, benefit_group: benefit_group, census_employee: existing_census_employee) }

          let!(:saved_census_employee) do
            ee = CensusEmployee.find(existing_census_employee.id)
            ee.benefit_group_assignments = [benefit_group_assignment]
            ee.save
            ee
          end

          context "and publish the plan year and associate census employee with employee_role" do
            before do
              plan_year.publish!
              saved_census_employee.employee_role = employee_role
              saved_census_employee.save
            end
  
            it "existing census employee should be employee_role_linked status" do
              expect(CensusEmployee.find(saved_census_employee.id).aasm_state).to eq "employee_role_linked"
            end

            it "new cenesus employee instance should fail validation" do
              expect(duplicate_census_employee.valid?).to be_falsey
              expect(duplicate_census_employee.errors[:base].first).to match(/Employee with this identifying information is already active/)
            end

            context "and existing employee instance is terminated" do
              before do
                saved_census_employee.terminate_employment(TimeKeeper.date_of_record)
                saved_census_employee.save
              end

              it "should be in terminated state" do
                expect(saved_census_employee.aasm_state).to eq "employment_terminated"
              end

              it "new instance should save" do
                expect(duplicate_census_employee.save!).to be_truthy
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
end

  context "validation for employment_terminated_on" do
    let(:census_employee) {FactoryGirl.build(:census_employee, employer_profile: employer_profile, hired_on: TimeKeeper.date_of_record.beginning_of_year)}

    it "should fail when terminated date before than hired date" do
      census_employee.employment_terminated_on = census_employee.hired_on - 10.days
      expect(census_employee.valid?).to be_falsey
      expect(census_employee.errors[:employment_terminated_on].any?).to be_truthy
    end

    it "should success" do
      census_employee.employment_terminated_on = census_employee.hired_on + 10.days
      expect(census_employee.valid?).to be_truthy
      expect(census_employee.errors[:employment_terminated_on].any?).to be_falsey
    end
  end
end
