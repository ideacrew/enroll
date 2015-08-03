require "rails_helper"

RSpec.describe "employers/employer_profiles/_primary_nav AS BROKER" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:person) { FactoryGirl.create(:person, :first_name=>'fred', :last_name=>'flintstone'  )} 
  let(:current_user) { FactoryGirl.create(:user, :roles => ['broker_agency_staff'], :person => person) }
  before :each do
    @employer_profile = employer_profile
    sign_in current_user
    current_user.person.broker_role = BrokerRole.new
    current_user.person.broker_role.provider_kind = 'broker'
    current_user.person.broker_role.npn = rand(100000)
    current_user.person.broker_role.broker_agency_profile_id = 99
    current_user.person.broker_role.save!
  end
  it "should display the standard tabs for Employer [broker and employer control]" do
    #allow(current_user.person.broker_role).to receive('broker_agency_profile_id').and_return(88)
    #allow(current_user).to receive("has_broker_agency_staff_role?").and_return(true)
    render "employers/employer_profiles/primary_nav"
    expect(rendered).to have_selector('a', :text=>'Home')
    expect(rendered).to have_selector('small', :text=>'Profile')
    expect(rendered).to match(/tab=profile/)
    expect(rendered).to have_selector('small', :text=>'Benefits')
    expect(rendered).to match(/tab=benefits/)
    expect(rendered).to have_selector('small', :text=>'Employees')
    expect(rendered).to match(/tab=employees/)
    expect(rendered).to have_selector('small', :text=>'Documents')
    expect(rendered).to match(/tab=documents/)
  end
  it "should show different tabs when Broker not employer" do
    #allow(current_user).to receive("has_broker_agency_staff_role?").and_return(true)
    #allow(current_user.person.broker_role).to receive('broker_agency_profile_id').and_return(88)
    render "employers/employer_profiles/primary_nav"
    expect(rendered).to_not have_selector('small', :text=>'Inbox')
    expect(rendered).to have_selector('small', :text=>'Families')
    expect(rendered).to match(/tab=families/)
    expect(rendered).to_not match(/broker_agency\/active_broker/)
  end
end
RSpec.describe "employers/employer_profiles/_primary_nav AS EMPLOYER" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile) }
  let(:person) { FactoryGirl.create(:person) }
  let(:current_user) { FactoryGirl.create(:user, :roles => [], :person => person) }
  before :each do
    @employer_profile = employer_profile
    sign_in current_user
  end
  it "should display the standard tabs for Employer[broker and employer control]" do
    #allow(current_user.person.broker_role).to receive('broker_agency_profile_id').and_return(88)
    render "employers/employer_profiles/primary_nav"
    expect(rendered).to have_selector('a', :text=>'Home')
    expect(rendered).to have_selector('small', :text=>'Profile')
    expect(rendered).to match(/tab=profile/)
    expect(rendered).to have_selector('small', :text=>'Benefits')
    expect(rendered).to match(/tab=benefits/)
    expect(rendered).to have_selector('small', :text=>'Employees')
    expect(rendered).to match(/tab=employees/)
    expect(rendered).to have_selector('small', :text=>'Documents')
    expect(rendered).to match(/tab=documents/)
  end 

  it "should display different tabs for Employer" do
    #allow(current_user.person.broker_role).to receive('broker_agency_profile_id').and_return(88)
    render "employers/employer_profiles/primary_nav"
    expect(rendered).to have_selector('small', :text=>'Inbox')
    expect(rendered).to_not have_selector('small', :text=>'Families')
    expect(rendered).to_not match(/tab=familiess/)
    expect(rendered).to match(/broker_agency\/active_broker/)
  end
end
