# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SponsoredBenefits::Forms::PlanDesignProposal, type: :model, dbclean: :after_each do
  context 'osse eligibility' do
    let!(:organization) do
      create(
        :sponsored_benefits_plan_design_organization,
        sponsor_profile_id: nil,
        sic_code: '0197'
      )
    end

    let!(:persist_proposal) do
      form = described_class.new(params.merge('osse_eligibility' => 'false'))
      form.save
    end

    let(:plan_design_proposal) { organization.reload.plan_design_proposals[0] }
    let(:employer_profile) { plan_design_proposal.profile }
    let(:benefit_sponsorship) { employer_profile.benefit_sponsorships[0] }

    let(:params) do
      {
        'organization' => organization,
        'title' => 'Quote Number Eleven',
        'effective_date' => organization.calculate_start_on_options.last[1],
        'osse_eligibility' => osse_eligibility
      }
    end

    before do
      form = described_class.new(params.merge('proposal_id' => plan_design_proposal.id.to_s))
      form.save
    end

    context 'when true' do
      let(:osse_eligibility) { 'true' }

      it 'should store eligibility' do
        osse_eligibility = benefit_sponsorship.reload.eligibility_for(:bqt_osse_eligibility, plan_design_proposal.effective_date)
        expect(osse_eligibility).to be_present
        expect(osse_eligibility.is_eligible_on?(plan_design_proposal.effective_date)).to be_truthy
      end
    end

    context 'when false' do
      let(:osse_eligibility) { 'true' }

      it 'should term eligibility' do
        osse_eligibility = benefit_sponsorship.reload.eligibility_for(
          :bqt_osse_eligibility,
          plan_design_proposal.effective_date
        )
        expect(osse_eligibility.is_eligible_on?(plan_design_proposal.effective_date)).to be_truthy

        form =
          described_class.new(
            params.merge(
              'proposal_id' => plan_design_proposal.id.to_s,
              'osse_eligibility' => 'false'
            )
          )
        form.save

        osse_eligibility = benefit_sponsorship.reload.eligibility_for(
          :bqt_osse_eligibility,
          plan_design_proposal.effective_date
        )
        expect(osse_eligibility.is_eligible_on?(plan_design_proposal.effective_date)).to be_falsey
      end
    end
  end
end
