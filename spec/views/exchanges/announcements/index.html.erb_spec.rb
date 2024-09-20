require 'rails_helper'

describe "exchanges/announcements/index.html.erb" do
  let!(:user) { FactoryBot.create(:user, :with_hbx_staff_role) }
  before :each do
    stub_template "ui-components/v1/navs/primary_nav" => 'nav_bar'
    sign_in user
    assign(:announcements, Announcement.current)
    allow(view).to receive(:policy_helper).and_return(double("ConsumerRole", updateable?: true, access_new_consumer_application_sub_tab?: true, access_outstanding_verification_sub_tab?: true, access_identity_verification_sub_tab?: true,
                                                                             begin_resident_enrollment?: true, can_access_user_account_tab?: true, view_admin_tabs?: true, view_the_configuration_tab?: true, can_send_secure_message?: true,
                                                                             can_manage_qles?: true, modify_admin_tabs?: true))
    render template: "exchanges/announcements/index.html.erb"
  end

  it "should display announcements area" do
    expect(rendered).to have_selector('div.announcements')
  end

  it "should display title" do
    expect(rendered).to have_selector('h1', text: 'Announcements')
  end

  it "should display filter button" do
    expect(rendered).to have_selector('a', text: 'Current')
    expect(rendered).to have_selector('a', text: 'All')
  end

  it "should display announcements table" do
    expect(rendered).to have_selector('table.table')
    expect(rendered).to have_text('Current Announcements')
    expect(rendered).to have_text('Msg Start Date')
    expect(rendered).to have_text('Msg End Date')
    expect(rendered).to have_text('Audience')
  end

  it "should display the form of announcement" do
    expect(rendered).to have_selector('form.form-horizontal')
  end
end

