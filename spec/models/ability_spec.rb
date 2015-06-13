require "cancan/matchers"
require "rails_helper"

describe "User" do
  describe "abilities" do
    subject(:ability){ Ability.new(user) }
    let(:user) { FactoryGirl.create(:user) }

    context "when is an hbx staff user" do
      let(:user) { FactoryGirl.create(:user, :hbx_staff) }

      it { should be_able_to(:edit_plan_year, PlanYear.new) }
    end

    context "when is user" do
      it { should_not be_able_to(:edit_plan_year, PlanYear.new) }
    end

    context "update employee" do
      let(:employer_profile){ FactoryGirl.create(:employer_profile)}
      let(:employee) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id)}

      context "when is hbx_staff user" do
        let(:user) { FactoryGirl.create(:user, :hbx_staff) }

        it "can update when change dob" do
          employee.dob = Date.current
          should be_able_to(:update, employee)
        end

        it "can update when change ssn" do
          employee.ssn = "123321456"
          should be_able_to(:update, employee)
        end
      end

      context "when is employer_staff user" do
        let(:user) { FactoryGirl.create(:user, :employer_staff) }

        context "not linked" do
          before do
            allow(employee).to receive(:eligible?).and_return(true)
          end

          it "can update when change dob" do
            employee.dob = Date.current
            should be_able_to(:update, employee)
          end

          it "can update when change ssn" do
            employee.ssn = "123321456"
            should be_able_to(:update, employee)
          end
        end

        context "has linked" do
          before do
            allow(employee).to receive(:eligible?).and_return(false)
          end

          it "can not update when change dob" do
            employee.dob = Date.current
            should_not be_able_to(:update, employee)
          end

          it "can not update when change ssn" do
            employee.ssn = "123321456"
            should_not be_able_to(:update, employee)
          end
        end
      end

      context "when is normal user" do
        it "can not update when change dob" do
          employee.dob = Date.current
          should_not be_able_to(:update, employee)
        end

        it "can not update when change ssn" do
          employee.ssn = "123321456"
          should_not be_able_to(:update, employee)
        end
      end
    end
  end
end

