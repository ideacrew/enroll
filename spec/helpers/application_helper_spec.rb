require "rails_helper"

RSpec.describe ApplicationHelper, :type => :helper do
  describe "#portal_display_name" do
    it "returns the portal display title" do
      expect(helper.portal_display_name('consumer_profiles')).to eq("<img src=\"/assets/icons/icon-individual.png\" alt=\"Icon individual\" /> &nbsp; I'm an Individual/Family")
      expect(helper.portal_display_name('employer_profiles')).to eq("<img src=\"/assets/icons/icon-business-owner.png\" alt=\"Icon business owner\" /> &nbsp; I'm an Employer")
      expect(helper.portal_display_name('profiles')).to eq("<img src=\"/assets/icons/icon-expert.png\" alt=\"Icon expert\" /> &nbsp; I'm a Broker")
      expect(helper.portal_display_name('broker_roles')).to eq("<img src=\"/assets/icons/icon-expert.png\" alt=\"Icon expert\" /> &nbsp; I'm a Broker")
      expect(helper.portal_display_name('hbx_profiles')).to eq("<img src=\"/assets/icons/icon-exchange-admin.png\" alt=\"Icon exchange admin\" /> &nbsp; I'm HBX Staff")
    end
  end

  describe "#format_date_with_hyphens" do
    it "returns date with hyphens" do
      expect(helper.format_date_with_hyphens(TimeKeeper.date_of_record)).to eq(TimeKeeper.date_of_record.to_s.gsub("/","-"))
    end
  end
end