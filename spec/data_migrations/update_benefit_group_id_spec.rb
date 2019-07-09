require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"
require File.join(Rails.root, "app", "data_migrations", "update_benefit_group_id")

describe UpdateBenefitGroupId, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  include_context "setup employees with benefits"

  let(:given_task_name) { "update_benefit_group_id" }
  subject { UpdateBenefitGroupId.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update benefit group id", dbclean: :after_each do
    let!(:effective_on) {effective_period.min}
    let!(:ce)  { census_employees[0]}
    let!(:person) {FactoryBot.create(:person, first_name: ce.first_name, last_name: ce.last_name, ssn:ce.ssn)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person:person)}
    let!(:employee_role) { FactoryBot.create(:benefit_sponsors_employee_role, person: person, employer_profile: abc_profile, census_employee_id: ce.id, benefit_sponsors_employer_profile_id: abc_profile.id)}
    let!(:initial_enrollment) { 
      hbx_enrollment = FactoryBot.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                          household: family.active_household, 
                          aasm_state: "coverage_enrolled",
                          family: family,
                          effective_on: effective_on,
                          rating_area_id: initial_application.recorded_rating_area_id,
                          sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                          sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                          benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                          benefit_package_id: initial_application.benefit_packages.first.id,
                          employee_role_id: employee_role.id,
                          submitted_at: Date.new(2018,6,21)
                          ) 
      hbx_enrollment.benefit_sponsorship = benefit_sponsorship
      hbx_enrollment.save!
      hbx_enrollment
    }
    let!(:initial_hbx_enrollment_member) {FactoryBot.create(:hbx_enrollment_member, applicant_id: person.id, hbx_enrollment: initial_enrollment) }

    before do
      ENV['benefit_package_id'] = current_benefit_package.id
      ENV['enrollment_hbx_id'] = initial_enrollment.hbx_id
      ce.update_attributes(:employee_role_id => employee_role.id )
    end
    it "should update benefit group id" do
      initial_enrollment.update_attributes!(benefit_package_id: nil)
      expect(initial_enrollment.benefit_group_id).to eq(nil)
      subject.migrate
      initial_enrollment.reload
      expect(initial_enrollment.benefit_package_id).to eq(current_benefit_package.id)
    end
  end
end
