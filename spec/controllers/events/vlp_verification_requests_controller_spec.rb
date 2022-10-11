require "rails_helper"

describe Events::VlpVerificationRequestsController do
  describe "#call with a person" do
    let(:person) { FactoryBot.create(:person, :with_consumer_role) }
    let(:outbound_event_name) { "acapi.info.events.lawful_presence.vlp_verification_request" }
    let(:rendered_template) { double }
    let(:coverage_start_date) { double }
    let(:mock_end_time) { (mock_now + 24.hours).to_i }
    let(:mock_now) { Time.mktime(2015,5,21,12,29,39) }

    before do
      @event_name = ""
      @body = nil
      event_subscriber = ActiveSupport::Notifications.subscribe(outbound_event_name) do |e_name, s_at, e_at, m_id, payload|
        @event_name = e_name
        @body = payload
      end
      allow(Time).to receive(:now).and_return(mock_now)
      expect(controller).to receive(:render_to_string).with(
          "events/lawful_presence/vlp_verification_request", {:formats => ["xml"], :locals => {
          :individual => person,
          :coverage_start_date => coverage_start_date
      }}).and_return(rendered_template)
      controller.call(LawfulPresenceDetermination::VLP_VERIFICATION_REQUEST_EVENT_NAME, nil, nil, nil, {:person => person, :coverage_start_date => coverage_start_date } )
      ActiveSupport::Notifications.unsubscribe(event_subscriber)
    end

    it "should send out a message to the bus with the request to validate ssa" do
      expect(@event_name).to eq outbound_event_name
      expect(@body).to eq ({:body => rendered_template, :individual_id => person.hbx_id, :retry_deadline => mock_end_time})
    end

    it "stores verification history element" do
      expect(person.consumer_role.lawful_presence_determination.vlp_requests.count).to be > 0
    end

    xit "stores verification history element with proper verification type" do
      expect(person.consumer_role.verification_types.by_name("Citizenship").first.type_history_elements.first.action).to eq "DHS Hub Request"
    end

    it "stores reference to event_request document" do
      expect(person.consumer_role.lawful_presence_determination.vlp_requests.first.id).to eq BSON::ObjectId.from_string(
          person.consumer_role.verification_types.by_name("Citizenship").first.type_history_elements.first.event_request_record_id)
    end
  end
end
