require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::Employers::EmployerProfilesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }
    let!(:security_question)  { FactoryGirl.create_default :security_question }

    let(:person) { FactoryGirl.create(:person) }
    let(:user) { FactoryGirl.create(:user, :person => person)}

    let!(:site)                  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_sponsor)       { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)      { benefit_sponsor.employer_profile }
    let!(:rating_area)           { FactoryGirl.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)          { FactoryGirl.create_default :benefit_markets_locations_service_area }
    let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

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
      let!(:employees) {
        FactoryGirl.create_list(:census_employee, 2, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship)
      }
      render_views

      before do
        benefit_sponsorship.save!
        sign_in user
        get :show, id: benefit_sponsor.profiles.first.id, tab: 'employees'
        allow(employer_profile).to receive(:active_benefit_sponsorship).and_return benefit_sponsorship
      end

      it "should render show template" do
        expect(response).to render_template("show")
      end

      it "should return http success" do
        expect(response).to have_http_status(:success)
      end

      it 'shows the employees' do
        employees.each do |employee|
          expect(response.body).to have_content(employee.full_name)
        end
      end
    end
  end
end
