require "rails_helper"

describe Events::IndividualsController do
  describe "#created with an individual created event" do
    let(:individual) { double }
    let(:outbound_event_name) { "acapi.info.events.individual.created" }
    let(:rendered_template) { double }

    it "should send out a message to the bus with the rendered individual object" do
      @event_name = ""
      @body = nil
      event_subscriber = ActiveSupport::Notifications.subscribe(outbound_event_name) do |e_name, s_at, e_at, m_id, payload|
        @event_name = e_name
        @body = payload.stringify_keys["body"]
      end
      expect(controller).to receive(:render_to_string).with(
        "created", {:formats => ["xml"], :locals => {
         :individual => individual
        }}).and_return(rendered_template)
      controller.created(nil, nil, nil, {:individual => individual})
      ActiveSupport::Notifications.unsubscribe(event_subscriber)
      expect(@event_name).to eq outbound_event_name
      expect(@body).to eq rendered_template
    end
  end

  describe "#updated with an individual updated event" do
    let(:individual) { double }
    let(:outbound_event_name) { "acapi.info.events.individual.updated" }
    let(:rendered_template) { double }

    it "should send out a message to the bus with the rendered individual object" do
      @event_name = ""
      @body = nil
      event_subscriber = ActiveSupport::Notifications.subscribe(outbound_event_name) do |e_name, s_at, e_at, m_id, payload|
        @event_name = e_name
        @body = payload.stringify_keys["body"]
      end
      expect(controller).to receive(:render_to_string).with(
        "created", {:formats => ["xml"], :locals => {
         :individual => individual
        }}).and_return(rendered_template)
      controller.updated(nil, nil, nil, {:individual => individual})
      ActiveSupport::Notifications.unsubscribe(event_subscriber)
      expect(@event_name).to eq outbound_event_name
      expect(@body).to eq rendered_template
    end
  end
end
