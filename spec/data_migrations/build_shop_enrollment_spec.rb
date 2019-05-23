require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "build_shop_enrollment")

describe BuildShopEnrollment, dbclean: :after_each do
  skip "ToDo rake was never updated to new model, check if we can remove it" do

  let(:given_task_name) { "build_shop_enrollment" }
  subject { BuildShopEnrollment.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  describe "creating a new shop enrollment", dbclean: :after_each do
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:person) { FactoryBot.create(:person, :with_employee_role)}
    let!(:benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year)}
    let(:plan_year) { FactoryBot.create(:plan_year, employer_profile: person.employee_roles[0].employer_profile, aasm_state: "active")}
    let(:census_employee) { FactoryBot.create(:census_employee, employer_profile: plan_year.employer_profile)}
    let(:enrollment_params) {{primary_hbx_id: person.hbx_id, effective_on: TimeKeeper.date_of_record, plan_year_state:plan_year.aasm_state, new_hbx_id: "1234567", fein: plan_year.employer_profile.parent.fein, hios_id: nil, active_year: nil, enr_aasm_state: nil, coverage_kind: nil, waiver_reason: nil}}

    before do
      person.employee_roles[0].update_attributes(census_employee_id: census_employee.id)
      census_employee.update_attributes(employee_role_id: person.employee_roles[0].id)
    end

    context "without providing plan details" do

      before do
        subject.migrate
        person.reload
      end
      
      with_modified_env enrollment_params do
        it "should create a new enrollment" do
          enrollments = person.primary_family.active_household.hbx_enrollments
          expect(enrollments.size).to eq 1
        end

        it "should have the given effective_on date" do
          expect(person.primary_family.active_household.hbx_enrollments.first.effective_on).to eq TimeKeeper.date_of_record
        end

        it "should have the updated hbx_id" do
          expect(person.primary_family.active_household.hbx_enrollments.first.hbx_id).to eq "1234567"
        end

        it "should be in enrolled statuses" do
          expect(HbxEnrollment::ENROLLED_STATUSES.include?(person.primary_family.active_household.hbx_enrollments.first.aasm_state)).to eq true
        end

        it "should create enrollment with reference plan id" do
          expect(person.primary_family.active_household.hbx_enrollments.first.plan_id).to eq benefit_group.reference_plan.id
        end

        it "should create hbx enrollment member records" do
          expect(person.primary_family.active_household.hbx_enrollments.first.hbx_enrollment_members.size).to eq 1
        end

        it "should have one hbx enrollment member record as primary" do
          expect(person.primary_family.active_household.hbx_enrollments.first.hbx_enrollment_members.where(is_subscriber: true).size).to eq 1
        end
      end
    end

    context "with plan details" do
      with_modified_env hios_id: plan.hios_id, active_year: plan.active_year do
        it "should create enrollment with the given plan id" do
          plan = Plan.first
          subject.migrate
          person.reload
          expect(person.primary_family.active_household.hbx_enrollments.first.plan_id).to eq plan.id
        end
      end
    end

    context "creating dental waiver enrollment" do
      before do
        subject.migrate
        person.reload
      end
      
      with_modified_env enr_aasm_state: "inactive", coverage_kind: "dental" do
        it "should generate a dental enrollment" do
          expect(person.primary_family.active_household.hbx_enrollments.first.coverage_kind).to eq "dental"
        end

        it "should generate a waiver" do
          expect(person.primary_family.active_household.hbx_enrollments.first.aasm_state).to eq "inactive"
        end
      end
    end
  end
end
end
