# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe 'HbxEnrollmentListSponsorCostCalculator', dbclean: :around_each do
  include_context 'setup benefit market with market catalogs and product packages'
  include_context 'setup initial benefit application'

  let(:census_employee) {create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile, benefit_group: current_benefit_package, hired_on: hired_on, created_at: employee_created_at, updated_at: employee_updated_at)}
  let!(:update_person) do
    @person = Person.create!(first_name: census_employee.first_name, last_name: census_employee.last_name, ssn: census_employee.ssn, dob: census_employee.dob, gender: 'male', version: 51)
    versions = []
    (1..50).each do |v|
      person = @person.dup
      person.assign_attributes(version: v, id: nil, user_id: BSON::ObjectId('5dc05dc22ca7fcc9287fa700'))
      versions << person
    end

    @person.versions << versions
    @person.save!

    @employee_role = @person.employee_roles.build(
        benefit_sponsors_employer_profile_id: census_employee.employer_profile, census_employee: census_employee, hired_on: census_employee.hired_on)

    census_employee.employee_role = @employee_role
    census_employee.save!
  end

  let(:current_effective_date) {TimeKeeper.date_of_record.beginning_of_month}
  let(:effective_on) {current_effective_date}
  let(:hired_on) {TimeKeeper.date_of_record - 3.months}
  let(:employee_created_at) {hired_on}
  let(:employee_updated_at) {employee_created_at}
  let!(:shop_family) {FactoryBot.create(:family, :with_primary_family_member, person: @person)}
  let(:aasm_state) {:active}
  let(:enrollment_kind) {'open_enrollment'}
  let(:special_enrollment_period_id) {nil}
  let(:hbx_enrollment_member) {FactoryBot.build(:hbx_enrollment_member, is_subscriber: true, applicant_id: shop_family.family_members.first.id, coverage_start_on: (TimeKeeper.date_of_record).beginning_of_month, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month)}
  let(:child_care_subsidy) { 0.0 }

  let!(:shop_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      household: shop_family.latest_household,
                      coverage_kind: 'health',
                      family: shop_family,
                      effective_on: effective_on,
                      enrollment_kind: enrollment_kind,
                      kind: 'employer_sponsored',
                      submitted_at: effective_on - 10.days,
                      benefit_sponsorship_id: benefit_sponsorship.id,
                      sponsored_benefit_package_id: current_benefit_package.id,
                      sponsored_benefit_id: current_benefit_package.sponsored_benefits[0].id,
                      employee_role_id: @employee_role.id,
                      benefit_group_assignment_id: census_employee.active_benefit_group_assignment.id,
                      special_enrollment_period_id: special_enrollment_period_id,
                      hbx_enrollment_members: [hbx_enrollment_member],
                      eligible_child_care_subsidy: child_care_subsidy
    )
  end

  let(:subject) {HbxEnrollmentListSponsorCostCalculator::HbxEnrollmentRosterMapper}

  before do
    @group_mapper = subject.new([shop_enrollment.id], current_benefit_package.sponsored_benefits[0])
  end

  it 'should return form object without errors' do
    @group_mapper.each do |gm|
      expect(gm.class).to be BenefitSponsors::Members::MemberGroup
    end
  end

  it 'should return enrollment hash' do
    enrollment_details = @group_mapper.search_criteria([shop_enrollment.id])
    expect(enrollment_details.first['people_ids']).to eq [@person.id]
  end

  describe 'HbxEnrollmentRosterMapper' do

    context 'rosterize_hbx_enrollment' do
      let(:enrollment_ids) { [shop_enrollment.id] }

      context 'always include child care subsidy' do

        it 'should pass child care subsidy along with group_enrollment' do
          mapper = HbxEnrollmentListSponsorCostCalculator::HbxEnrollmentRosterMapper.new(enrollment_ids, shop_enrollment.sponsored_benefit)
          agg_result = mapper.search_criteria(enrollment_ids).first
          people_merge = mapper.get_person_details(agg_result['people_ids'])
          member_group = mapper.rosterize_hbx_enrollment(agg_result.merge({"people" => people_merge}))

          expect(member_group.group_enrollment).to be_present
          expect(member_group.group_enrollment.eligible_child_care_subsidy).to be_a(Money)
          expect(member_group.group_enrollment.eligible_child_care_subsidy.to_f).to eq(0.0)
        end
      end

      context 'when childcare subsidy amount present on enrollment' do

        let(:child_care_subsidy) { 150.0 }

        it 'should pass child care subsidy along with group_enrollment' do
          mapper = HbxEnrollmentListSponsorCostCalculator::HbxEnrollmentRosterMapper.new(enrollment_ids, shop_enrollment.sponsored_benefit)
          agg_result = mapper.search_criteria(enrollment_ids).first
          people_merge = mapper.get_person_details(agg_result['people_ids'])
          member_group = mapper.rosterize_hbx_enrollment(agg_result.merge({"people" => people_merge}))

          expect(member_group.group_enrollment).to be_present
          expect(member_group.group_enrollment.eligible_child_care_subsidy).to be_a(Money)
          expect(member_group.group_enrollment.eligible_child_care_subsidy.to_f).to eq(150.0)
        end
      end
    end
  end
end
