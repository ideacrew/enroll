# frozen_string_literal: true

require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/support/benefit_sponsors_site_spec_helpers"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market"

RSpec.describe Operations::Eligible::EligibilityBatchHandler,
               type: :model,
               dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let(:batch_handler) do
    described_class.new(
      batch_size: batch_size,
      record_kind: "individual",
      effective_date: Date.today
    )
  end
  let(:batch_size) { 5 }
  let(:event) { Success(double) }

  before do
    allow(batch_handler).to receive(:event).and_return(event)
    allow(event.success).to receive(:publish).and_return(true)
  end

  context ".trigger_batch_requests" do
    context "when query returns records" do
      before do
        allow(batch_handler).to receive(:query).and_return(double(count: 103))
      end

      it "should loop and send batch requests" do
        (0..20).each do |index|
          expect(batch_handler.logger).to receive(:info).with(
            /trigger_batch_request with offset: #{index * batch_size}/i
          )
        end
        expect(batch_handler.logger).to receive(:info).with(
          /trigger_batch_request sent 21 batch requests/i
        )
        batch_handler.trigger_batch_requests
      end
    end
  end

  context ".batch_request_options" do
    let(:batch_handler) do
      described_class.new(
        batch_size: batch_size,
        record_kind: "individual",
        effective_date: Date.today
      )
    end
    it "should include both default and current options" do
      output = batch_handler.batch_request_options(10)

      expect(output).to include(:batch_handler)
      expect(output).to include(:record_kind)
      expect(output).to include(:effective_date)

      expect(output[:batch_options]).to include(:batch_size)
      expect(output[:batch_options]).to include(:offset)
    end
  end

  context ".process_batch_request" do
    let(:batch_handler) do
      described_class.new(
        batch_size: batch_size,
        record_kind: "individual",
        effective_date: Date.today
      )
    end

    let!(:people) { create_list(:person, 10, :with_consumer_role) }
    it "should include both default and current options" do
      expect(batch_handler.logger).to receive(:info).with(
        /process_batch_request with {:offset=>5, :batch_size=>5} started/i
      )
      Person
        .all
        .offset(5)
        .each do |person|
          expect(batch_handler.logger).to receive(:info).with(
            /processing hbx_id: #{person.hbx_id} of ConsumerRole/i
          )
        end

      batch_handler.process_batch_request({ offset: 5, batch_size: 5 })
    end
  end
end
