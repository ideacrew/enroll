require 'rails_helper'

RSpec.describe "general_agencies/profiles/_families.html.erb", dbclean: :after_each do
  let(:general_agency_profile) { FactoryGirl.create(:general_agency_profile) }
  before :each do
    if individual_market_is_enabled?
      assign :general_agency_profiles, Kaminari.paginate_array([general_agency_profile]).page(0)
      render template: "general_agencies/profiles/_index.html.erb"
    end
  end
  context "individual market is enabled" do
    it 'should have title' do
      if individual_market_is_enabled?
        expect(rendered).to have_selector('h3', text: 'General Agencies')
      end
    end
    it 'should show general_agencies fields' do
      if individual_market_is_enabled?
        expect(rendered).to have_selector('th', text: 'Legal Name')
        expect(rendered).to have_selector('th', text: 'Fein')
      end
    end
    it 'should show general_agency_profile info' do
      if individual_market_is_enabled?
        expect(rendered).to have_selector('a', text: "#{general_agency_profile.legal_name}")
      end
    end
    it "should have status bar" do
      if individual_market_is_enabled?
        expect(rendered).to have_selector('div.button-group-wrapper')
        expect(rendered).to have_content('Applicant')
        expect(rendered).to have_content('Certified')
        expect(rendered).to have_content('Decertified')
        expect(rendered).to have_content('Pending')
        expect(rendered).to have_content('All')
      end
    end
    it "should show the state of general_agency_profile" do
      if individual_market_is_enabled?
        expect(rendered).to have_selector('td', text: "#{general_agency_profile.current_state}")
      end
    end
    it "should have input for status" do
      if individual_market_is_enabled?
        expect(rendered).to have_selector('input[value="is_applicant"]')
        expect(rendered).to have_selector('input[value="is_approved"]')
        expect(rendered).to have_selector('input[value="is_rejected"]')
        expect(rendered).to have_selector('input[value="is_suspended"]')
        expect(rendered).to have_selector('input[value="all"]')
      end
    end
  end
end
