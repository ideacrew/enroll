require "rails_helper"

RSpec.describe HbxProfilesController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/exchanges/hbx_profiles").to route_to("exchanges/hbx_profiles#index")
    end

    it "routes to #new" do
      expect(:get => "/exchanges/hbx_profiles/new").to route_to("exchanges/hbx_profiles#new")
    end

    it "routes to #show" do
      expect(:get => "/exchanges/hbx_profiles/1").to route_to("exchanges/hbx_profiles#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/exchanges/hbx_profiles/1/edit").to route_to("exchanges/hbx_profiles#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/exchanges/hbx_profiles").to route_to("exchanges/hbx_profiles#create")
    end

    it "routes to #update" do
      expect(:put => "/exchanges/hbx_profiles/1").to route_to("exchanges/hbx_profiles#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/exchanges/hbx_profiles/1").to route_to("exchanges/hbx_profiles#destroy", :id => "1")
    end

  end
end
