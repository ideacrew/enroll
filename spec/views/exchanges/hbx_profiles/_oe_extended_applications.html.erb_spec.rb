require 'rails_helper'

describe "exchanges/hbx_profiles/_oe_extended_applications.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, :person => person) }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile)}
  let!(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: "enrollment_extended", start_on: start_on)}

  before :each do
    allow(user).to receive(:has_tier3_subrole?).and_return true
    sign_in(user)
    assign(:plan_years, [plan_year])
    assign(:employer_profile, employer_profile)
    allow(view).to receive(:pundit_class).and_return(double("HbxProfile", can_extend_open_enrollment?: true))
    render template: "exchanges/hbx_profiles/_oe_extended_applications.html.erb"
  end

  it "should display plan year details" do
    expect(rendered).to have_text("Initial")
    expect(rendered).to have_text(plan_year.open_enrollment_end_on.strftime('%m/%d/%Y'))
    expect(rendered).to have_text(plan_year.aasm_state.to_s.humanize.titleize)
  end

  it "should have close open enrollment link " do
    expect(rendered).to have_link("Close Open Enrollment", href: close_extended_open_enrollment_exchanges_hbx_profiles_path(id: employer_profile.id, plan_year_id: plan_year.id))
  end
end

