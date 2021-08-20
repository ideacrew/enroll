require "rails_helper"

RSpec.describe "general_agencies/profiles/edit.html.erb" do
  let(:organization) {FactoryBot.create(:organization)}
  let(:general_agency_profile) { FactoryBot.create(:general_agency_profile, organization: organization) }
  let(:general_agency_staff_role) { FactoryBot.create(:general_agency_staff_role) }

  before :each do
    general_agency_staff_role.update_attributes(general_agency_profile_id: general_agency_profile.id)
    org_form = Forms::GeneralAgencyProfile.find(general_agency_profile.id)
    assign :organization, org_form
    assign :general_agency_profile, general_agency_profile
    assign :id, general_agency_profile.id
    EnrollRegistry[:general_agency].feature.stub(:is_enabled).and_return(false)
    Enroll::Application.reload_routes!
    render template: "general_agencies/profiles/edit.html.erb"
  end

  it "should have title" do
    expect(rendered).to have_selector('h4', text: 'Personal Information')
    expect(rendered).to have_selector('h4', text: 'General Agency Information')
  end
  it "should have language select" do
    expect(rendered).to have_selector('#general_agency_language_select')
  end
  it "should have organization details displayed" do
    expect(rendered).to have_selector("#organization_first_name", count: 1)
  end
  ## TODO: need to fix it when fixing UI
  # it "should have a hidden field organization id" do
  #   expect(rendered).to have_selector("[name='organization[id]']", count: 1)
  # end
end
