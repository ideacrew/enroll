# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"

RSpec.describe Operations::Eligible::EligibilityBatchHandler,
               type: :model,
               dbclean: :after_each do
  include Dry::Monads[:result, :do]
  
  context ".trigger_batch_requests" do
    context "when query returns records" do
      let(:batch_handler) do
        described_class.new(
          batch_size: 5,
          record_kind: "individual",
          effective_date: Date.today
        )
      end

      let(:event) { Success(double) }

      before do
        allow(batch_handler).to receive(:query).and_return(double(count: 103))
        allow(batch_handler).to receive(:event).and_return(event)
        allow(event.success).to receive(:publish).and_return(true)
      end

      it "should loop and send batch request" do
        batch_handler.trigger_batch_requests
      end
    end
  end
end
