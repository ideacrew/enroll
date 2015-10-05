require "pundit/rspec"
require "rails_helper"

describe CensusEmployeePolicy do
  subject { described_class }
  let(:employer_profile){ FactoryGirl.create(:employer_profile)}


  permissions :delink? do
    context "already linked" do
      let(:employee) { FactoryGirl.build(:census_employee, employer_profile_id: employer_profile.id, aasm_state: "employee_role_linked") }

      it "grants access when hbx_staff" do
        expect(subject).to permit(FactoryGirl.create(:user, :hbx_staff), employee)
      end

      it "grants access when broker" do
        expect(subject).to permit(FactoryGirl.create(:user, :broker), employee)
      end

      it "grants access when broker_agency_staff" do
        expect(subject).to permit(FactoryGirl.create(:user, :broker_agency_staff), employee)
      end

      it "denies access when normal user" do
        expect(subject).not_to permit(FactoryGirl.create(:user), employee)
      end
    end

    context "not linked" do
      let(:employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, aasm_state: "eligible") }

      it "denies access when hbx_staff" do
        expect(subject).not_to permit(FactoryGirl.create(:user, :hbx_staff), employee)
      end

      it "denies access when broker" do
        expect(subject).not_to permit(FactoryGirl.create(:user, :broker), employee)
      end

      it "denies access when broker_agency_staff" do
        expect(subject).not_to permit(FactoryGirl.create(:user, :broker_agency_staff), employee)
      end

      it "denies access when normal user" do
        expect(subject).not_to permit(FactoryGirl.create(:user), employee)
      end
    end
  end

  permissions :update? do
    let(:employee) { FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, aasm_state: "eligible") }

    context "when is hbx_staff user" do
      let(:user) { FactoryGirl.create(:user, :hbx_staff) }

      it "grants access when change dob" do
        employee.dob = TimeKeeper.date_of_record
        expect(subject).to permit(user, employee)
      end

      it "grants access when change ssn" do
        employee.ssn = "123321456"
        expect(subject).to permit(user, employee)
      end
    end

    context "when is broker user" do
      let(:user) { FactoryGirl.create(:user, :broker) }

      it "grants access when change dob" do
        employee.dob = TimeKeeper.date_of_record
        expect(subject).to permit(user, employee)
      end

      it "grants access when change ssn" do
        employee.ssn = "123321456"
        expect(subject).to permit(user, employee)
      end
    end

    context "when is normal user" do
      let(:user) { FactoryGirl.create(:user) }

      it "denies access when change dob" do
        employee.dob = TimeKeeper.date_of_record
        expect(subject).not_to permit(user, employee)
      end

      it "denies access when change ssn" do
        employee.ssn = "123321456"
        expect(subject).not_to permit(user, employee)
      end
    end

    context "when is employer_staff user" do
      let(:user) { FactoryGirl.create(:user, :employer_staff) }

      context "not linked" do
        before do
          allow(employee).to receive(:eligible?).and_return(true)
        end

        it "grants access when change dob" do
          employee.dob = TimeKeeper.date_of_record
          expect(subject).to permit(user, employee)
        end

        it "grants access when change ssn" do
          employee.ssn = "123321456"
          expect(subject).to permit(user, employee)
        end
      end

      context "has linked" do
        before do
          allow(employee).to receive(:eligible?).and_return(false)
        end

        it "grants access when change dob" do
          employee.dob = TimeKeeper.date_of_record
          expect(subject).to permit(user, employee)
        end

        it "grants access when change ssn" do
          employee.ssn = "123321456"
          expect(subject).to permit(user, employee)
        end
      end
    end
  end
end
