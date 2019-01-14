require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_profile_tab.html.erb" do
  let(:employer_profile) {FactoryBot.build(:employer_profile)}
  let(:person) {FactoryBot.build(:person)}
  let(:organization) {FactoryBot.build(:organization)}

  context "employer profile tab" do
    before :each do
      allow(employer_profile).to receive(:staff_roles).and_return([person])
      assign :employer_profile, employer_profile
      render partial: "employers/employer_profiles/my_account/profile_tab.html.erb"
    end

    it "should display the offices info of employer" do
      expect(rendered).to match /#{employer_profile.legal_name} Offices/
    end

    it "should display the compnay info" do
      expect(rendered).to match /#{employer_profile.legal_name} Info/
      expect(rendered).to match /Registered legal name/
      expect(rendered).to match /Doing Business As/
      expect(rendered).to match /Fein/
    end

    it "should display the contact" do
      expect(rendered).to match /Staff/
      expect(rendered).to match /#{person.full_name}/
    end
  end

  context "employer_profile should have home page" do
    before :each do
      allow(employer_profile).to receive(:staff_roles).and_return([person])
      allow(employer_profile).to receive(:organization).and_return(organization)
      allow(organization).to receive(:home_page).and_return("http://google.com")
      assign :employer_profile, employer_profile
      render partial: "employers/employer_profiles/my_account/profile_tab.html.erb"
    end

    it "should show the link of home page" do
      expect(rendered).to match /Web URL/
      expect(rendered).to have_selector("a[href='http://google.com']")
    end
  end
end
