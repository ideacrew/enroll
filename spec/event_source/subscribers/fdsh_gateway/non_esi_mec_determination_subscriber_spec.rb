# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Subscribers::FdshGateway::NonEsiMecDeterminationSubscriber, dbclean: :after_each do
  let(:payload) { { message: 'Hello world!!' } }
  let(:connection_manager_instance) { EventSource::ConnectionManager.instance }
  let(:connection) do
    connection_manager_instance.find_connection(publish_params)
  end

  let(:publish_params) do
    { protocol: :amqp,
      publish_operation_name: 'fdsh.eligibilities.non_esi.non_esi_determination_complete' }
  end

  let(:publish_operation) do
    connection_manager_instance.find_publish_operation(publish_params)
  end

  let(:subscribe_params) do
    { protocol: :amqp,
      subscribe_operation_name: 'on_fdsh.eligibilities.non_esi' }
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
  let(:routing_key) do
    queue_proxy.channel_proxy.async_api_channel_item.subscribe.bindings.amqp[:routing_key]
  end

  let(:call_application_publish) do
    ::FinancialAssistance::Operations::Applications::NonEsi::H31::AddNonEsiMecDetermination.new.call(
      { payload: payload }
    )
  end

  after { channel_proxy.queue_delete(queue_proxy.name) }

  context 'exchanges, queues' do
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
