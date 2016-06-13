require "rails_helper"

describe Importers::ConversionEmployeeUpdate, :dbclean => :after_each do
  describe "an employee without dependents is updated" do
    context "and the sponsor employer is not found" do
      let(:bogus_employer_fein) { "000093939" }
      subject { Importers::ConversionEmployeeUpdate.new(:fein => bogus_employer_fein) }

      before(:each) do
        allow(Organization).to receive(:where).with({:fein => bogus_employer_fein}).and_return([])
        subject.valid?
      end

      it "adds an 'employer not found' error to the instance" do
        expect(subject.errors.get(:fein)).to include("does not exist")
      end
    end

    context "and the sponsor employer is found" do


      let(:employer_profile) { FactoryGirl.create(:employer_profile, profile_source: 'conversion') }

      let(:carrier_profile) { FactoryGirl.create(:carrier_profile) }

      let(:renewal_health_plan)   {
        FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "health", active_year: 2016, carrier_profile_id: carrier_profile.id)
      }

      let(:current_health_plan)   {
        FactoryGirl.create(:plan, :with_premium_tables, coverage_kind: "health", active_year: 2015, renewal_plan_id: renewal_health_plan.id, carrier_profile_id: carrier_profile.id)
      }

      let(:plan_year)            {
        py = FactoryGirl.create(:plan_year,
          start_on: Date.new(2015, 7, 1),
          end_on: Date.new(2016, 6, 30),
          open_enrollment_start_on: Date.new(2015, 6, 1),
          open_enrollment_end_on: Date.new(2015, 6, 10),
          employer_profile: employer_profile
          )

        py.benefit_groups = [
          FactoryGirl.build(:benefit_group,
            title: "blue collar",
            plan_year: py,
            reference_plan_id: current_health_plan.id,
            elected_plans: [current_health_plan]
            )
        ]
        py.save(:validate => false)
        py.update_attributes({:aasm_state => 'active'})
        py
      }

      let(:employer_fein) { 
        employer_profile.fein
      } 

      context "and a pre-existing employee record is found" do

        let(:conversion_employee_props) do
           {
              :fein => employer_fein,
              :subscriber_ssn => census_employee.ssn,
              :subscriber_dob => census_employee.dob.strftime("%m/%d/%Y"),
              :subscriber_name_first => census_employee.first_name,
              :subscriber_name_last => census_employee.last_name,
              :hire_date => census_employee.hired_on.strftime("%m/%d/%Y"),
              :subscriber_gender => census_employee.gender
           } 
        end

        let(:census_employee) {
           FactoryGirl.create(:census_employee, :employer_profile => employer_profile)
        }

        context "and the employee's name is changed" do

          let(:new_employee_f_name) {
             census_employee.first_name + "dkfjklasdf"
          }

          let(:conversion_employee_update) { Importers::ConversionEmployeeUpdate.new(changed_name_props) }

          let(:changed_name_props) {
             conversion_employee_props.merge(:subscriber_name_first => new_employee_f_name)
          }

          context "and the employee's record has not changed since import" do

            let(:updated_census_employee) {
               CensusEmployee.find(census_employee.id)
            }

            it "should save succesfully" do
              expect(conversion_employee_update.save).to be_truthy
            end

            it "should change the employee name" do
               conversion_employee_update.save
               expect(updated_census_employee.first_name).to eq new_employee_f_name
            end
          end

          context "and the employee's record has changed since import" do
            it "adds an 'update inconsistancy: employee record changed' error to the instance"
            it "adds the error to the instance's error[:base] array"
          end
        end

        context "and the employee's gender and dob are changed" do
          context "and the employee's record has not changed since import" do
            it "should change the employee gender and dob"
          end

          context "and the employee's record has changed since import" do
            it "adds an 'update inconsistancy: employee record changed' error"
            it "adds the error to the instance's error[:base] array"
          end
        end

        context "and the employee's address is changed" do
          context "and the employee's address record has not changed since import" do
            it "should change the employee address"
          end

          context "and the employee's address record has changed since import" do
            it "adds an 'update inconsistancy: employee address record changed' error"
            it "adds the error to the instance's error[:base] array"
          end
        end

        context "and a dependent is added" do
          context "and the dependent date of birth is in the future" do
            it "adds an 'dependent date of birth in the future not allowed' error"
            it "adds the error to the instance's error[:base] array"
          end

          context "and the dependent is a spouse" do
            it "should add the dependent spouse"
          end

          context "and the dependent is a child" do
            context "and the child is 26 years of age or older on the renewal effective date" do
              it "should not add the child dependent"
              it "adds a 'over-age dependent add failure' error"
            end

            context "and the child is under age 26 on the renewal effective date" do
              it "should add the dependent"
            end
          end

          context "and the dependent is any relationship besides spouse, child or domestic partner" do
            it "should not add the dependent"
            it "adds a 'dependent add failure: invalid relationship' error to the instance"
          end

        end

      end
    end
  end

  describe "an employee with dependents is updated" do
    context "and a dependent is added" do
      context "and the dependent is found in employee record" do
        it "adds an 'update inconsistancy: duplicate employee dependent not allowed' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end

      context "and the dependent is not found in employee record" do
        context "and the dependent is a spouse" do
          it "should add the spouse dependent"
        end

        context "and the dependent is a domestic partner" do
          it "should add the domestic partner dependent"
        end

        context "and the dependent is a child" do
          context "and the child is 26 years of age or older on the renewal effective date" do
            context "and the child is disabled" do
              it "should add the child dependent"
            end

            context "and the child is not disabled" do
              it "should not add the child dependent"
              it "adds a 'dependent add failure: over-age child' error to the instance"
            end
          end

          context "and the child is under age 26 on the renewal effective date" do
            it "should add the child dependent"
          end
        end

      end
    end

    context "and a dependent is deleted" do
      it "adds an 'update not supported: dependent delete' error to the instance"
      it "adds the error to the instance's error[:base] array"
    end

    context "and the employee dependent's name and ssn is changed" do
      context "and the employee dependent's record has not changed since import" do
        it "should change the employee dependent name and ssn"
      end

      context "and the employee dependent's record has changed since import" do
        it "adds an 'update inconsistancy: employee dependent record changed' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end
    end

    context "and the employee dependent's gender and dob are changed" do
      context "and the employee dependent's record has not changed since import" do
        it "should change the employee dependent gender and dob"
      end

      context "and the employee dependent's record has changed since import" do
        it "adds an 'update inconsistancy: employee dependent record changed' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end
    end

    context "and the employee dependent's address is changed" do
      context "and the employee dependent's record has not changed since import" do
        it "should change the employee dependent address"
        it "should not change the employee address"
      end

      context "and the employee dependent's record has changed since import" do
        it "adds an 'update inconsistancy: employee dependent record changed' error to the instance"
        it "adds the error to the instance's error[:base] array"
      end
    end
  end
end
