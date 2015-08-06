require "rails_helper"

describe Events::EmployersController do
  describe "#call with an employer binder paid event" do
    let(:employer_profile) { double }
    let(:binder_event_name) { "acapi.info.events.employer.binder_premium_paid" }
    let(:rendered_template) { double }

    it "should send out a message to the bus with the rendered employer object" do
      @event_name = ""
      @body = nil
      subber = ActiveSupport::Notifications.subscribe(binder_event_name) do |e_name, s_at, e_at, m_id, payload|
        @event_name = e_name
        @body = payload.stringify_keys["body"]
      end
      expect(controller).to receive(:render_to_string).with(
        "updated", {:formats => ["xml"], :locals => {
         :employer => employer_profile
        }}).and_return(rendered_template)
      controller.call(EmployerProfile::BINDER_PREMIUM_PAID_EVENT_NAME, nil, nil, nil, {:employer => employer_profile})
      ActiveSupport::Notifications.unsubscribe(subber)
      expect(@event_name).to eq binder_event_name
      expect(@body).to eq rendered_template
    end
  end
end
