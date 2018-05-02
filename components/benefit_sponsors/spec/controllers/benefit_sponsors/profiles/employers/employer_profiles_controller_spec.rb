require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::Employers::EmployerProfilesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    let(:person) { FactoryGirl.create(:person) }
    let(:user) { FactoryGirl.create(:user, :person => person)}
    let(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :dc) }
    let(:benefit_sponsor) {FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site)}

    describe "GET show_pending" do
      before do
        sign_in user
        get :show_pending
      end

      it "should render show template" do
        expect(response).to render_template("show_pending")
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end
    end

    describe "GET show" do

      before do
        sign_in user
        get :show, id: benefit_sponsor.profiles.first.id
      end

      it "should render show template" do
        expect(response).to render_template("show")
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end
    end
  end
end
