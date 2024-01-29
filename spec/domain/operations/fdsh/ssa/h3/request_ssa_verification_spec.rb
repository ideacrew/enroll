# frozen_string_literal: true

require "rails_helper"

# module Operations for class RequestSsaVerification
module Operations
  RSpec.describe Fdsh::Ssa::H3::RequestSsaVerification, dbclean: :after_each do

    let(:person) {FactoryBot.create(:person, :with_consumer_role)}

    context "request without a person" do
      it "should fail" do
        result = described_class.new.call(nil)
        expect(result).to be_failure
      end
    end

    context "success" do
      before do
        @result = described_class.new.call(person)
      end

      it "should pass" do
        expect(@result).to be_success
      end

      it "should create a job" do
        job = ::Transmittable::Job.where(key: :ssa_verification).last
        expect(job).to be_truthy
        expect(job.process_status.latest_state).to eq :transmitted
      end

      it "should create a transmission" do
        transmission = ::Transmittable::Transmission.where(key: :ssa_verification_request).last
        expect(transmission).to be_truthy
        expect(transmission.process_status.latest_state).to eq :succeeded
      end

      it "should create a transaction" do
        transaction = ::Transmittable::Transaction.where(key: :ssa_verification_request).last
        expect(transaction).to be_truthy
        expect(transaction.json_payload).to be_truthy
        expect(transaction.process_status.latest_state).to eq :succeeded
      end

      it 'person should have a transaction' do
        expect(person.transactions.count).to eq 1
      end
    end
  end
end
