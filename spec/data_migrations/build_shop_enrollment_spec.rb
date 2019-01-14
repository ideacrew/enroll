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

  describe "creating a new shop enrollment", dbclean: :after_each do
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:person) { FactoryBot.create(:person, :with_employee_role)}
    let!(:benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year)}
    let(:plan_year) { FactoryBot.create(:plan_year, employer_profile: person.employee_roles[0].employer_profile, aasm_state: "active")}
    let(:census_employee) { FactoryBot.create(:census_employee, employer_profile: plan_year.employer_profile)}
    before do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("effective_on").and_return(TimeKeeper.date_of_record)
      allow(ENV).to receive(:[]).with("plan_year_state").and_return(plan_year.aasm_state)
      allow(ENV).to receive(:[]).with("new_hbx_id").and_return("1234567")
      allow(ENV).to receive(:[]).with("fein").and_return plan_year.employer_profile.parent.fein
      allow(ENV).to receive(:[]).with("hios_id").and_return nil
      allow(ENV).to receive(:[]).with("active_year").and_return nil
      allow(ENV).to receive(:[]).with("enr_aasm_state").and_return nil
      allow(ENV).to receive(:[]).with("coverage_kind").and_return nil
      allow(ENV).to receive(:[]).with("waiver_reason").and_return nil
      person.employee_roles[0].update_attributes(census_employee_id: census_employee.id)
      census_employee.update_attributes(employee_role_id: person.employee_roles[0].id)
    end

    context "without providing plan details" do

      before do
        subject.migrate
        person.reload
      end

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

    context "with plan details" do
      it "should create enrollment with the given plan id" do
        plan = Plan.first
        allow(ENV).to receive(:[]).with("hios_id").and_return plan.hios_id
        allow(ENV).to receive(:[]).with("active_year").and_return plan.active_year
        subject.migrate
        person.reload
        expect(person.primary_family.active_household.hbx_enrollments.first.plan_id).to eq plan.id
      end
    end

    context "creating dental waiver enrollment" do
      before do
        allow(ENV).to receive(:[]).with("enr_aasm_state").and_return "inactive"
        allow(ENV).to receive(:[]).with("coverage_kind").and_return "dental"
        subject.migrate
        person.reload
      end

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
