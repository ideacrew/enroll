# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Subscribers::ApplicationSubmitRenewalDraftSubscriber, dbclean: :after_each do
  let(:connection_manager_instance) { EventSource::ConnectionManager.instance }
  let(:connection) do
    connection_manager_instance.find_connection(publish_params)
  end

  let(:publish_params) do
    { protocol: :amqp,
      publish_operation_name: 'enroll.iap.applications.submit_renewal_draft' }
  end

  let(:publish_operation) do
    connection_manager_instance.find_publish_operation(publish_params)
  end

  let(:subscribe_params) do
    { protocol: :amqp,
      subscribe_operation_name: 'on_enroll.enroll.iap.applications' }
  end

  let(:subscribe_operation) do
    connection_manager_instance.find_subscribe_operation(subscribe_params)
  end

  let(:channel_proxy) { exchange_proxy.channel_proxy }
  let(:exchange_proxy) { publish_operation.subject }
  let(:queue_proxy) { subscribe_operation.subject }
  let(:bunny_exchange) { exchange_proxy.subject }
  let(:bunny_queue) { queue_proxy.subject }
  let(:bunny_consumer) { queue_proxy.consumers.first }

  let(:call_application_publish) do
    ::FinancialAssistance::Operations::Applications::MedicaidGateway::PublishApplication.new.call(
      { payload: { message: 'Hello world!!' }, event_name: 'submit_renewal_draft' }
    )
  end

  after { channel_proxy.queue_delete(queue_proxy.name) }

  context 'for exchanges, queues' do
    it 'should create exchanges and queues' do
      expect(bunny_exchange).to be_present
      expect(bunny_queue).to be_present
    end
  end

  context 'when valid event published' do
    it 'should publish payload with exchange' do
      expect(bunny_exchange).to receive(:publish).at_least(1).times
      call_application_publish
    end
  end
end
