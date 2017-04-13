require 'rails_helper'

RSpec.describe "welcome/index.html.erb", :type => :view do

  describe "a signed in user" do
    let(:user) { FactoryGirl.create(:user, oim_id: "test@enroll.com") }

    before :each do
      sign_in user
    end
    it "should has current_user oim_id" do
      render
      expect(rendered).to match /#{user.oim_id}/
      expect(rendered).not_to match /Broker Registration/
      expect(rendered).not_to match /General Agency Registration/
    end
  end

  describe "not signed in user" do
    # before :each do
    #   sign_in user
    # end
    it "shows registration if not signed in" do
      if individual_market_is_enabled?
        render
        expect(rendered).to match /Broker Registration/
        expect(rendered).to match /General Agency Registration/
      end
    end

    context "with general agency disabled" do
      before :each do
        allow(view).to receive(:general_agency_enabled?).and_return(false)
      end
      it "does not show general agency related links" do
        render
        expect(rendered).not_to match /General Agency Registration/
        expect(rendered).not_to match /General Agency Portal/
      end
    end
  end

  describe "Enabled/Disabled IVL market" do
  	shared_examples_for "IVL market status" do |status, value|
		  it "should #{status} Consumer/Family Portal registeration" do
		  	if value == false
					expect(rendered).not_to have_link('Consumer/Family Portal')
				else
					expect(rendered).to have_link('Consumer/Family Portal')
				end
		  end

		  it "should #{status} Assisted Consumer/Family Portal registeration" do
		  	if value == false
					expect(rendered).not_to have_link('Assisted Consumer/Family Portal')
				else
					expect(rendered).to have_link('Assisted Consumer/Family Portal')
				end
		  end
		end

		# it_behaves_like "IVL market status", "Enable", Settings.aca.market_kinds.include? "individual" # use it when we enable IVL market
		it_behaves_like "IVL market status", "Disabled", Settings.aca.market_kinds.include?("individual")
  end
end