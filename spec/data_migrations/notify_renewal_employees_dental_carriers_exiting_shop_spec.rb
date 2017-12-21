require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "notify_renewal_employees_dental_carriers_exiting_shop")

describe NotifyRenewalEmployeesDentalCarriersExitingShop do

  let(:given_task_name) { "notify_renewal_employees_dental_carriers_exiting_shop" }
  subject { NotifyRenewalEmployeesDentalCarriersExitingShop.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "#trigger notify_renewal_employees_dental_carriers_exiting_shop", type: :model, dbclean: :after_all do
    let!(:person) { FactoryGirl.create(:person, hbx_id: "19877154") }
    let!(:employer_profile) { create(:employer_with_planyear)}
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let!(:hbx_enrollment) { FactoryGirl.create(:hbx_enrollment, household: family.active_household, coverage_kind: "dental", kind: "employer_sponsored", plan_id: plan.id, employee_role_id: employee_role.id )}
    let!(:organization) {FactoryGirl.create(:organization, legal_name: "Delta Dental")}
    let!(:carrier_profile) {FactoryGirl.create(:carrier_profile, organization: organization)}
    let!(:plan) {FactoryGirl.create(:plan, :with_dental_coverage, carrier_profile: carrier_profile)}
    let!(:employee_role) { FactoryGirl.create(:employee_role, employer_profile: employer_profile, person: person, census_employee_id: census_employee.id) }
    let!(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile) }

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      census_employee.update_attributes(employee_role_id: employee_role.id)
    end

    it "should trigger notify_renewal_employees_dental_carriers_exiting_shop job in queue" do
      ActiveJob::Base.queue_adapter = :test
      ActiveJob::Base.queue_adapter.enqueued_jobs = []
      subject.migrate

      queued_job = ActiveJob::Base.queue_adapter.enqueued_jobs.find do |job_info|
        job_info[:job] == ShopNoticesNotifierJob
      end

      expect(queued_job[:args]).not_to be_empty
      expect(queued_job[:args].include?('notify_renewal_employees_dental_carriers_exiting_shop')).to be_truthy
      expect(queued_job[:args].include?("#{hbx_enrollment.census_employee.id.to_s}")).to be_truthy
      expect(queued_job[:args].third["hbx_enrollment"]).to eq hbx_enrollment.hbx_id.to_s
    end
  end
end
