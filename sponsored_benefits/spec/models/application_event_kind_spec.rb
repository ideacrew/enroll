require 'rails_helper'

RSpec.describe ApplicationEventKind, :type => :model do

  let(:valid_params) {
      {
        title: "Transfer to HBX Approved",
        description: "SHOP converted Employer has begun initial benefit coverage application period",
        resource_name: "employer_profile",
        event_name: "transfer_to_hbx_approved"
      }
    }

  let(:notice_trigger)  { FactoryGirl.create(:notice_trigger) }

  context "resource_kind parameter" do
    it "should" do
      ApplicationEventKind.create()
    end
  end

  context "key parameter" do
  end

  # employer_conversion_notice_trigger = NoticeTrigger.new(
  #   title: "Employer Conversion Notice",
  #   resource_publisher: "employer_profile",
  #   event_id: "transfer_to_hbx_approved",                 # trigger event
  #   template_id: "shop_14",                               # reference to notice template
  #   employer_profile: employer_profile,

  #   notice_trigger_element_group: NoticeTriggerElementGroup.new(
  #       primary_recipients: ["employer"],
  #       primary_recipient_delivery_method: ["paper"],
  #       secondary_recipients: ["employer"],
  #       secondary_recipient_delivery_method: ["email"],
  #     )
  #   )


end
