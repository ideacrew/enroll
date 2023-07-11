# frozen_string_literal: true

require 'rails_helper'

describe Effective::Datatables::BenefitSponsorsCoverageReportsDataTable, dbclean: :after_each do
  describe '#authorized?' do
    context 'when current user does not exist' do
      let(:user) { nil }
      let(:profile_id) { BSON::ObjectId.new.to_s }

      it 'should not authorize access' do
        expect(described_class.new(id: profile_id).authorized?(user, nil, nil, nil)).to eq(false)
      end
    end

    context 'when current user exists with valid staff role' do
      let(:user) { FactoryBot.create(:user) }
      let(:employer_profile) { FactoryBot.create(:benefit_sponsors_organizations_aca_shop_me_employer_profile) }
      let(:profile_id) { employer_profile.id }
      let(:policy) { double('BenefitSponsors::EmployerProfilePolicy', coverage_reports?: true) }

      before do
        allow(::BenefitSponsors::EmployerProfilePolicy).to receive(:new).with(user, employer_profile).and_return(policy)
      end

      it 'should not authorize access' do
        expect(described_class.new(id: profile_id).authorized?(user, nil, nil, nil)).to eq(true)
      end
    end
  end
end
