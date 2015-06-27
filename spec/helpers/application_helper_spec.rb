require "rails_helper"

RSpec.describe ApplicationHelper, :type => :helper do
  describe "#portal_display_name" do
    it "returns the portal display title" do
    	expect(helper.portal_display_name('consumer_profiles')).to eq("<img src=\"/assets/icons/icon-employee.png\" alt=\"Icon employee\" /> &nbsp; I'm an Individual/Family")
    	expect(helper.portal_display_name('employer_profiles')).to eq("<img src=\"/assets/icons/icon-business-owner.png\" alt=\"Icon business owner\" /> &nbsp; I'm an Employer")
    	expect(helper.portal_display_name('profiles')).to eq("<img src=\"/assets/icons/icon-expert.png\" alt=\"Icon expert\" /> &nbsp; I'm a Broker")
    	expect(helper.portal_display_name('broker_roles')).to eq("<img src=\"/assets/icons/icon-expert.png\" alt=\"Icon expert\" /> &nbsp; I'm a Broker")
    	expect(helper.portal_display_name('hbx_profiles')).to eq("<img src=\"/assets/icons/icon-exchange-admin.png\" alt=\"Icon exchange admin\" /> &nbsp; I'm HBX Staff")
    end
  end
end