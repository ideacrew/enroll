require 'rails_helper'

describe "exchanges/hbx_profiles/_edit_open_enrollment.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, :person => person) }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile)}
  let!(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile, aasm_state: "application_ineligible", start_on: start_on)}

  before :each do
    allow(user).to receive(:has_tier3_subrole?).and_return true
    sign_in(user)
    assign(:person, person)
    assign(:plan_year, plan_year)
    assign(:employer_profile, employer_profile)
    allow(view).to receive(:pundit_class).and_return(double("HbxProfile", can_extend_open_enrollment?: true))
    render template: "exchanges/hbx_profiles/_edit_open_enrollment.html.erb"
  end

  it "should display details" do
    expect(rendered).to have_text(employer_profile.organization.legal_name)
    expect(rendered).to have_text(plan_year.open_enrollment_end_on.strftime('%m/%d/%Y'))
    expect(rendered).to have_text(plan_year.start_on.strftime('%m/%d/%Y'))
    expect(rendered).to have_text("Please Choose New Open Enrollment Date:")
  end

  it "should have extend open enrollment link " do
    expect(rendered).to have_button("Extend Open Enrollment")
  end

  it "should have cancel link " do
    expect(rendered).to have_button("Cancel")
  end
end

