# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ::Operations::Eligibilities::Osse::TerminateEligibility,
               type: :model,
               dbclean: :after_each do

  let(:site) { ::BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_benefit_market }
  let(:benefit_market)  { site.benefit_markets.first }
  let(:dc_employer_organization)   { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site) }
  let(:dc_profile)                 { dc_employer_organization.employer_profile  }
  let(:benefit_sponsorship) do
    bs = dc_profile.add_benefit_sponsorship
    bs.save!
    bs
  end
  let(:subject_ref) { benefit_sponsorship.to_global_id }
  let(:termination_date) { TimeKeeper.date_of_record }

  let!(:eligibility) do
    benefit_sponsorship.eligibilities << build(:eligibility, :with_subject, :with_evidences)
    benefit_sponsorship.save!
    benefit_sponsorship.eligibilities.first
  end


  let(:required_params) do
    {
      subject_gid: subject_ref,
      evidence_key: :osse_subsidy,
      termination_date: termination_date
    }
  end

  let(:latest_osee_evidence) { eligibility.evidences.by_key(:osse_subsidy).last }

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when required attributes passed' do
    context 'when subject is benefit sponsorship' do

      it 'should be success' do
        result = subject.call(required_params)
        expect(result.success?).to be_truthy
      end

      it 'should terminate eligibility' do
        subject.call(required_params)
        eligibility.reload
        expect(eligibility.end_on).to eq(termination_date)
        expect(latest_osee_evidence.is_satisfied).to be_falsey
      end
    end

    context 'when subject is employee role' do
      let(:current_termination_date) {TimeKeeper.date_of_record.beginning_of_month.next_month}

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

      let!(:eligibility) do
        employee_role.eligibilities << build(:eligibility, :with_subject, :with_evidences)
        employee_role.save!
        employee_role.eligibilities.first
      end

      let(:subject_ref) { employee_role.to_global_id }

      it 'should be success' do
        result = subject.call(required_params)
        expect(result.success?).to be_truthy
      end

      it 'should terminate eligibility' do
        subject.call(required_params)
        eligibility.reload
        expect(eligibility.end_on).to eq(termination_date)
        expect(latest_osee_evidence.is_satisfied).to be_falsey
      end
    end
  end

  context 'when required attributes not passed' do
    it 'should fail with validation error' do
      result = subject.call(required_params.except(:termination_date))
      expect(result.failure?).to be_truthy
      expect(result.failure).to include("termination date missing")
    end
  end
end
