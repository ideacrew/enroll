require 'rails_helper'

  RSpec.configure do |c|
    c.include PortalHeaderHelper
  end

  RSpec.describe "Builds user with correct role" do
    let(:this_person) { FactoryGirl.build(:person) }
    let(:current_user) { FactoryGirl.build(:user, :person=>this_person)}
    let(:employer_profile){ FactoryGirl.build(:employer_profile) }
    let(:employer_staff_role){ FactoryGirl.create(:employer_staff_role, :person=>this_person, :employer_profile_id=>employer_profile.id)}
    let(:signed_in?){ true }
    let(:emp_id) {employer_profile.id}
    
    before(:each) do
    	sign_in current_user
    end
    
    it "returns I'm an Employer is user has correct role" do
      allow(this_person).to receive(:active_employer_staff_roles).and_return([employer_staff_role])
      current_user.roles=['employer_staff']
      current_user.save
      expect(portal_display_name(controller)).to eq "<a class=\"portal\" href=\"/employers/employer_profiles/"+ emp_id.to_s + "\"><img src=\"/images/icons/icon-business-owner.png\" alt=\"Icon business owner\" /> &nbsp; I'm an Employer</a>"
    end
    
    it "returns Welcome prompt if user doesnt have correct role" do
      current_user.roles=['']
      current_user.save
      expect(portal_display_name(controller)).to eq "<a class='portal'>Welcome to the District's Health Insurance Marketplace</a>"
    end
  end