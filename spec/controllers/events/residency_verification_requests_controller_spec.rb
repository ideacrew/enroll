# frozen_string_literal: true

require "rails_helper"

describe Events::ResidencyVerificationRequestsController do
  describe "#call with a person" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:outbound_event_name) { "acapi.info.events.residency.verification_request" }
    let(:rendered_template) { double }
    let(:mock_end_time) { (mock_now + 24.hours).to_i }
    let(:mock_now) { Time.mktime(2015,5,21,12,29,39) }

    before do
      allow(EnrollRegistry[:location_residency_verification_type].feature).to receive(:is_enabled).and_return(true)
      person.consumer_role.verification_type_history_elements.delete_all
      @event_name = ""
      @body = nil
      event_subscriber = ActiveSupport::Notifications.subscribe(outbound_event_name) do |e_name, _s_at, _e_at, _m_id, payload|
        @event_name = e_name
        @body = payload
      end
      allow(Time).to receive(:now).and_return(mock_now)
      expect(controller).to receive(:render_to_string).with(
        "events/residency/verification_request", {:formats => [:xml], :locals => {
          :individual => person
        }}
      ).and_return(rendered_template)
      controller.call(ConsumerRole::RESIDENCY_VERIFICATION_REQUEST_EVENT_NAME, nil, nil, nil, {:person => person})
      ActiveSupport::Notifications.unsubscribe(event_subscriber)
      allow(EnrollRegistry[:location_residency_verification_type].feature).to receive(:is_enabled).and_return(true)
    end

    it "should send out a message to the bus with the request to validate local residency" do
      expect(@event_name).to eq outbound_event_name
      expect(@body).to eq({:body => rendered_template, :individual_id => person.hbx_id, :retry_deadline => mock_end_time})
    end

    xit "stores verification history element" do
      expect(person.consumer_role.local_residency_requests.count).to be > 0
    end

    it "stores verification history element with proper verification type" do
      expect(person.verification_types.active.where(type_name: VerificationType::LOCATION_RESIDENCY).first.type_history_elements.first.action).to eq "Local Hub Request"
    end

    it "stores reference to event_request document" do
      expect(person.consumer_role.local_residency_requests.first.id).to eq BSON::ObjectId.from_string(
        person.verification_types.active.where(type_name: VerificationType::LOCATION_RESIDENCY).first.type_history_elements.first.event_request_record_id
      )
    end
  end
end
