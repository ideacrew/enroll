# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe HbxEnrollmentListSponsorCostCalculator, :dbclean => :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  let(:person) { FactoryBot.create(:person) }
  let(:person2) do
    pr = FactoryBot.create(:person)
    person.ensure_relationship_with(pr, 'child')
    pr
  end

  let(:family) do
    fm = FactoryBot.create(:family, :with_primary_family_member, person: person)
    FactoryBot.create(:family_member, family: fm, person: person2)
    fm.save!
    fm
  end

  let(:benefit_package)   { initial_application.benefit_packages.first }
  let(:sponsored_benefit) { benefit_package.sponsored_benefits.first }
  let!(:census_employee)  { FactoryBot.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: abc_profile, active_benefit_group_assignment: benefit_package.id) }
  let(:employee_role)     { FactoryBot.create(:benefit_sponsors_employee_role, employer_profile: abc_profile, person: person, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
  let!(:benefit_group_assignment) { census_employee.active_benefit_group_assignment }
  let!(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      :with_enrollment_members,
                      :with_product,
                      enrollment_members: family.family_members.to_a,
                      household: family.active_household,
                      family: family,
                      aasm_state: "coverage_selected",
                      effective_on: initial_application.start_on,
                      rating_area_id: initial_application.recorded_rating_area_id,
                      sponsored_benefit_id: benefit_package.health_sponsored_benefit.id,
                      sponsored_benefit_package_id: benefit_package.id,
                      benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                      employee_role_id: employee_role.id)
  end

  context 'for invalid relationships' do
    before do
      person.person_relationships.first.update_attributes!(kind: "parent")
      @enr_cal_obj = HbxEnrollmentListSponsorCostCalculator.new(benefit_sponsorship)
    end

    it 'should not raise any error' do
      hbx_ids = HbxEnrollment.all.pluck(:_id)
      expect { @enr_cal_obj.calculate(sponsored_benefit, hbx_ids) }.not_to raise_error
    end
  end
end
