# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ::Operations::Eligibilities::Osse::BuildEligibility, type: :model, dbclean: :after_each do

  let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
  let(:benefit_market)  { site.benefit_markets.first }
  let(:dc_employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site) }
  let(:dc_profile)                 { dc_employer_organization.employer_profile  }
  let(:benefit_sponsorship)         { dc_profile.add_benefit_sponsorship }
  let(:subject_ref) { benefit_sponsorship.to_global_id }
  let(:effective_date) { TimeKeeper.date_of_record }

  let(:required_params) do
    {
      subject_gid: subject_ref,
      evidence_key: :osse_subsidy,
      evidence_value: "true",
      effective_date: effective_date
    }
  end

  before do
    benefit_sponsorship.save!
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when required attributes passed' do
    context 'when subject is benefit sponsorship' do

      it 'should be success' do
        result = subject.call(required_params)
        expect(result.success?).to be_truthy
      end

      it 'should create eligibility' do
        result = subject.call(required_params)
        expect(result.success).to be_a(AcaEntities::Eligibilities::Osse::Eligibility)
      end
    end

    context 'when subject is employee role' do
      let(:current_effective_date) {TimeKeeper.date_of_record.beginning_of_month.next_month}

      include_context 'setup benefit market with market catalogs and product packages'
      include_context 'setup initial benefit application'

      let(:person) { FactoryBot.create(:person, :with_employee_role, :with_family) }
      let(:family) { person.primary_family }
      let!(:census_employee) do
        ce = FactoryBot.create(:census_employee, :with_active_assignment, benefit_sponsorship: benefit_sponsorship, employer_profile: benefit_sponsorship.profile, benefit_group: current_benefit_package)
        ce.update_attributes!(employee_role_id: person.employee_roles[0].id)
        person.employee_roles[0].update_attributes(census_employee_id: ce.id, benefit_sponsors_employer_profile_id: benefit_sponsorship.profile.id, employer_profile_id: nil)
        ce
      end

      let(:employee_role) { person.employee_roles[0] }

      let(:subject_ref) { employee_role.to_global_id }

      it 'should be success' do
        result = subject.call(required_params)
        expect(result.success?).to be_truthy
      end

      it 'should create eligibility' do
        result = subject.call(required_params)
        expect(result.success).to be_a(AcaEntities::Eligibilities::Osse::Eligibility)
      end
    end

    context 'when subject is consumer role' do
      let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_family) }
      let(:family) { person.primary_family }
      let(:consumer_role) { person.consumer_role }
      let(:subject_ref) { consumer_role.to_global_id }

      it 'should be success' do
        result = subject.call(required_params)
        expect(result.success?).to be_truthy
      end

      it 'should create eligibility' do
        result = subject.call(required_params)
        expect(result.success).to be_a(AcaEntities::Eligibilities::Osse::Eligibility)
      end

      context 'when aca_ivl_osse_effective_beginning_of_year got enabled' do
        before do
          EnrollRegistry[:aca_ivl_osse_effective_beginning_of_year].feature.stub(:is_enabled).and_return(true)
        end

        it "should return eligibility start date as beginning of year" do
          result = subject.call(required_params)
          expect(result.success.start_on).to eq effective_date.beginning_of_year
        end
      end

      context 'when aca_ivl_osse_effective_beginning_of_year got disabled' do
        before do
          EnrollRegistry[:aca_ivl_osse_effective_beginning_of_year].feature.stub(:is_enabled).and_return(false)
        end

        it "should return eligibility start date as effective_date" do
          result = subject.call(required_params)
          expect(result.success.start_on).to eq effective_date
        end
      end
    end
  end

  context 'when required attributes not passed' do
    it 'should fail with validation error' do
      result = subject.call(required_params.except(:effective_date))
      expect(result.failure?).to be_truthy
      expect(result.failure).to include("effective date missing")
    end
  end
end
