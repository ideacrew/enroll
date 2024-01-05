# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BenefitSponsors::BenefitSponsorships::EligibilitiesEventLog, type: :model, dbclean: :around_each do
  before { DatabaseCleaner.clean }

  describe "benefit sponsorship event log" do
    context "when sponsorship passed as subject" do

      let(:benefit_sponsorship)  { FactoryBot.create(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
      let(:user) { FactoryBot.create(:user, identity_verified_date: nil) }

      context ".save" do
        let(:params) do
          {
            account_id: user.id,
            subject_gid: benefit_sponsorship.to_global_id,
            correlation_id: "a156ad4c031",
            host_id: :enroll,
            event_category: :osse_eligibility,
            event_name: "events.determine_eligibility",
            event_time: DateTime.new
          }
        end

        it "should persist event log" do
          described_class.create(params)

          expect(described_class.count).to eq 1
        end

        it "should find events from collection" do
          expect(
            described_class.where(
              params.slice(:account_id, :event_category)
            ).first
          ).to eq described_class.first
        end
      end
    end
  end
end
