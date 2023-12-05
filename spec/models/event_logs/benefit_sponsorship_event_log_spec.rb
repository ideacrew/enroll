# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventLogs::BenefitSponsorshipEventLog, type: :model, dbclean: :around_each do
  before { DatabaseCleaner.clean }

  describe "benefit sponsorship event log" do
    context "when sponsorship passed as subject" do

      let(:benefit_sponsorship)  { FactoryBot.create(:benefit_sponsors_benefit_sponsorship, :with_full_package) }
      
      context ".save" do
        let(:params) do
          {
            subject_gid: benefit_sponsorship.to_global_id,
            correlation_id: "a156ad4c031",
            session_id: "222_222_220",
            account_id: "d156ad4c031g32324tf0",
            host_id: :enroll,
            event_category: :osse_eligibility,
            trigger: "determine_eligibility",
            response: "success",
            log_level: :debug,
            severity: :debug,
            event_time: DateTime.new
          }
        end

        it "should persist event log" do
          described_class.create(params)

          expect(described_class.count).to eq 1
        end

        it "should find events from collection" do
          expect(
            described_class.find(
              params.slice(:subject_gid, :event_category)
            ).first
          ).to eq described_class.first
        end
      end
    end
  end
end
