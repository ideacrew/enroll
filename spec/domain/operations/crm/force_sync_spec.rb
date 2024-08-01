# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Crm::ForceSync do
  include Dry::Monads[:result]

  before :all do
    DatabaseCleaner.clean
  end

  after :all do
    DatabaseCleaner.clean
  end

  describe '#call' do
    context 'success' do
      let(:primary1_hbx_id) { 'primary1' }
      let(:primary2_hbx_id) { 'primary2' }
      let(:primary3_hbx_id) { 'primary3' }
      let(:params) { { primary_hbx_ids: [primary1_hbx_id, primary2_hbx_id, primary3_hbx_id] } }

      let(:publish_instance) { instance_double(Operations::Crm::Family::Publish) }

      let(:message1) { "Successfully published event: events.families.created_or_updated for family with primary person hbx_id: #{primary1_hbx_id}" }
      let(:message2) { "Provide a valid person_hbx_id to fetch person. Invalid input hbx_id: primary2_hbx_id" }
      let(:message3) { "Primary Family does not exist with given hbx_id: #{primary3_hbx_id}" }

      before do
        allow(::Operations::Crm::Family::Publish).to receive(:new).and_return(publish_instance)
        allow(publish_instance).to receive(:call).with(hbx_id: primary1_hbx_id).and_return(
          Success(message1)
        )

        allow(publish_instance).to receive(:call).with(hbx_id: primary2_hbx_id).and_return(
          Failure(message2)
        )

        allow(publish_instance).to receive(:call).with(hbx_id: primary3_hbx_id).and_return(
          Failure(message3)
        )
      end

      it 'returns a success monad' do
        expect(subject.call(params).success?).to be_truthy
      end

      it 'creates a CSV ' do
        message = subject.call(params).success
        csv_file_name = message.split(': ').last
        expect(
          File.exist?(csv_file_name)
        ).to be_truthy
      end

      it 'logs the results of the operation in CSV' do
        message = subject.call(params).success
        csv_file_name = message.split(': ').last
        csv = CSV.read(csv_file_name)
        expect(csv[1]).to eq([primary1_hbx_id, 'Success', message1])
        expect(csv[2]).to eq([primary2_hbx_id, 'Failed', message2])
        expect(csv[3]).to eq([primary3_hbx_id, 'Failed', message3])
      end
    end

    context 'failure' do
      context 'when primary_hbx_ids is not an array' do
        let(:params) { { primary_hbx_ids: 'primary1' } }

        it 'returns a failure monad' do
          expect(subject.call(params).failure).to eq('Invalid input for primary_hbx_ids: primary1. Provide an array of HBX IDs.')
        end
      end

      context 'when primary_hbx_ids is an empty array' do
        let(:params) { { primary_hbx_ids: [] } }

        it 'returns a failure monad' do
          expect(subject.call(params).failure).to eq('Invalid input for primary_hbx_ids: []. Provide an array of HBX IDs.')
        end
      end

      context 'when primary_hbx_ids array has non-string elements' do
        let(:params) { { primary_hbx_ids: [100] } }

        it 'returns a failure monad' do
          expect(subject.call(params).failure).to eq('Invalid input for primary_hbx_ids: [100]. Provide an array of HBX IDs.')
        end
      end
    end
  end

  after :all do
    # Clean up the CSV files created during the test
    Dir.glob("#{Rails.root}/crm_force_sync_*.csv").each do |file|
      FileUtils.rm(file)
    end
  end
end
