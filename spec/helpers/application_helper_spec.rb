require "rails_helper"

RSpec.describe ApplicationHelper, :type => :helper do
  describe "#portal_display_name" do
    it "returns the portal display title" do
    	expect(helper.portal_display_name('consumer_profiles')).to eq("I'm an Individual/Family")
    	expect(helper.portal_display_name('employer_profiles')).to eq("I'm an Employer")
    	expect(helper.portal_display_name('profiles')).to eq("I'm a Broker")
    	expect(helper.portal_display_name('broker_roles')).to eq("I'm a Broker")
    	expect(helper.portal_display_name('hbx_profiles')).to eq("I'm HBX Staff")
    end
  end
end