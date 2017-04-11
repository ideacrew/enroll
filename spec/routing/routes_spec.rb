require 'rails_helper'

RSpec.describe "routing", :type => :routing do
  it "routes /insured/consumer_role/immigration_document_options to consumer_roles#immigration_document_options" do
    expect(:get => "/insured/consumer_role/immigration_document_options").to route_to(
      :controller => "insured/consumer_roles",
      :action => "immigration_document_options"
    )
  end
  
  describe "broker agency assign can be enabled or disabled via settings" do
    context "when enabled" do
      before do
        Settings.site.general_agency_enabled = true
        Enroll::Application.reload_routes!
      end
      it "routes to broker_agencies/profiles#assign by default" do
        expect(get: "/broker_agencies/profiles/1/assign").to route_to(
          controller: 'broker_agencies/profiles',
          action: 'assign',
          id: '1'
        )
      end
    end

    context "when disabled" do
      before do
        Settings.site.general_agency_enabled = false
        Enroll::Application.reload_routes!
      end

      it "assign becomes unroutable" do
        expect(get: "/broker_agencies/profiles/1/assign").not_to be_routable
      end
    end
  end

  describe "broker agency update_assign can be enabled or disabled via settings" do
    context "when enabled" do
      before do
        Settings.site.general_agency_enabled = true
        Enroll::Application.reload_routes!
      end
      it "routes to broker_agencies/profiles#update_assign by default" do
        expect(post: "/broker_agencies/profiles/1/update_assign").to route_to(
          controller: 'broker_agencies/profiles',
          action: 'update_assign',
          id: '1'
        )
      end
    end

    context "when disabled" do
      before do
        Settings.site.general_agency_enabled = false
        Enroll::Application.reload_routes!
      end

      it "update_assign becomes unroutable" do
        expect(post: "/broker_agencies/profiles/1/update_assign").not_to be_routable
      end
    end
  end
end
