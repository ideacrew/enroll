require 'rails_helper'

RSpec.describe PortalHeaderHelper, :type => :helper do

  describe "portal_display_name" do

    let(:signed_in?){ true }

    context "has_employer_staff_role?" do
      let(:employer_profile){ FactoryGirl.build(:employer_profile) }
      let(:employer_profile2){ FactoryGirl.build(:employer_profile) }
      let(:employer_staff_role){ FactoryGirl.create(:employer_staff_role, aasm_state:'is_closed',:employer_profile_id=>employer_profile.id)}
      let(:employer_staff_role2){ FactoryGirl.create(:employer_staff_role,aasm_state:'is_active',:employer_profile_id=>employer_profile2.id)}
      let(:this_person) { FactoryGirl.build(:person, :employer_staff_roles => [employer_staff_role, employer_staff_role2]) }
      let(:current_user) { FactoryGirl.build(:user, :person=>this_person)}
      let(:emp_id) {current_user.person.active_employer_staff_roles.first.employer_profile_id}

      it "should have I'm an Employer link when user has active employer_staff_role" do
        expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/employers/employer_profiles/"+ emp_id.to_s + "\"><img src=\"/images/icons/icon-business-owner.png\" alt=\"Icon business owner\" /> &nbsp; I'm an Employer</a>"
      end

      it "should have Welcome prompt when user has no active role" do
        allow(current_user).to receive(:has_employer_staff_role?).and_return(false)
        expect(portal_display_name(controller)).to eq "<a class='portal'>Welcome to the District's Health Insurance Marketplace</a>"
      end
    end

    context "has_consumer_role?" do
      let(:current_user) { FactoryGirl.build(:user, :identity_verified_date => Time.now)}
      before(:each) do
        allow(current_user).to receive(:has_consumer_role?).and_return(true)
        allow(controller).to receive(:controller_path).and_return("insured")
      end

      it "should have Individual and Family link when user completes RIDP and Consent form" do
        expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/families/home\"><img src=\"/images/icons/icon-family.png\" alt=\"Icon family\" /> &nbsp; Individual and Family</a>"
      end

      it "should not have Individual and Family link for users with no identity_verified_date" do
        current_user.identity_verified_date = nil
        current_user.save
        expect(portal_display_name(controller)).to eq "<a class='portal'><img src=\"/images/icons/icon-family.png\" alt=\"Icon family\" /> &nbsp; Individual and Family</a>"
      end
    end

  end
end