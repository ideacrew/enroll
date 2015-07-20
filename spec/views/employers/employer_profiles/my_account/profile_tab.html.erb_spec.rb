require "rails_helper"

RSpec.describe "employers/employer_profiles/my_account/_profile_tab.html.erb" do
  let(:employer_profile) {FactoryGirl.build(:employer_profile)}
  let(:person) {FactoryGirl.build(:person)}

  context "employer profile tab" do
    before :each do
      allow(employer_profile).to receive(:owner).and_return(person)
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
      expect(rendered).to match /Web URL/
    end

    it "should display the contact" do
      expect(rendered).to match /Owner/
      expect(rendered).to match /#{person.full_name}/
    end
  end
end
