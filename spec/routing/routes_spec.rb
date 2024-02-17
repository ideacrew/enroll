require 'rails_helper'

RSpec.describe "routing", :type => :routing do

  it "routes /insured/consumer_role/immigration_document_options to consumer_roles#immigration_document_options" do
    expect(:get => "/insured/consumer_role/immigration_document_options").to route_to(
      :controller => "insured/consumer_roles",
      :action => "immigration_document_options"
    )
  end

  context "when notice engine is enabled" do
    routes { Notifier::Engine.routes }
    before :each do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:notices_tab).and_return(true)
    end

    it "successfully routes to /notifier/notice_kinds" do
      expect(:get => '/notice_kinds').to route_to(
        :controller => "notifier/notice_kinds",
        :action => "index"
      )
    end
  end

  context "when notice engine is disabled" do
    before do
      allow(EnrollRegistry).to receive(:feature_enabled?).with(:notices_tab).and_return(false)
    end

    it "does not route to /notifier/notice_kinds" do
      expect(:get => '/notice_kinds').not_to be_routable
    end
  end
end
