require "rails_helper"

describe Events::EmployersController do
  describe "#call with an employer binder paid event" do
    let(:employer_profile) { double }
    let(:outbound_event_name) { "acapi.info.events.employer.binder_premium_paid" }
    let(:rendered_template) { double }

    it "should have the right subscription information" do
      expect(Events::EmployersController.binder_paid_subscription_details).to eq EmployerProfile::BINDER_PREMIUM_PAID_EVENT_NAME
    end

    it "should send out a message to the bus with the rendered employer object" do
      @event_name = ""
      @body = nil
      event_subscriber = ActiveSupport::Notifications.subscribe(outbound_event_name) do |e_name, s_at, e_at, m_id, payload|
        @event_name = e_name
        @body = payload.stringify_keys["body"]
      end
      expect(controller).to receive(:render_to_string).with(
        "updated", {:formats => ["xml"], :locals => {
         :employer => employer_profile
        }}).and_return(rendered_template)
      controller.binder_paid(nil, nil, nil, {:employer => employer_profile})
      ActiveSupport::Notifications.unsubscribe(event_subscriber)
      expect(@event_name).to eq outbound_event_name
      expect(@body).to eq rendered_template
    end
  end

  describe "#updated with an employer binder paid event" do
    let(:employer_profile) { double }
    let(:outbound_event_name) { "acapi.info.events.employer.updated" }
    let(:rendered_template) { double }

    it "should have the right subscription information" do
      expect(Events::EmployersController.updated_subscription_details).to eq EmployerProfile::EMPLOYER_PROFILE_UPDATED_EVENT_NAME
    end

    it "should send out a message to the bus with the rendered employer object" do
      @event_name = ""
      @body = nil
      event_subscriber = ActiveSupport::Notifications.subscribe(outbound_event_name) do |e_name, s_at, e_at, m_id, payload|
        @event_name = e_name
        @body = payload.stringify_keys["body"]
      end
      expect(controller).to receive(:render_to_string).with(
        "updated", {:formats => ["xml"], :locals => {
         :employer => employer_profile
        }}).and_return(rendered_template)
      controller.updated(nil, nil, nil, {:employer => employer_profile})
      ActiveSupport::Notifications.unsubscribe(event_subscriber)
      expect(@event_name).to eq outbound_event_name
      expect(@body).to eq rendered_template
    end
  end
end
