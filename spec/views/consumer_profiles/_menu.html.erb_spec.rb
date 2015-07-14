require 'rails_helper'

RSpec.describe "consumer_profiles/_menu.html.erb" do
  let(:person) {FactoryGirl.create(:person)}

  before :each do
    assign(:person, person)
    render "consumer_profiles/menu", :active_tab => "home-tab"
  end

  it "should display the main menu" do
    expect(rendered).to have_selector('a[href="/consumer_profiles/personal"]', text: 'Profile')
    expect(rendered).to have_selector('a[href="/consumer_profiles/plans"]', text: 'Plans')
    expect(rendered).to have_selector('a[href="#"]', text: 'Documents')
    expect(rendered).to have_selector('a[href="/consumer_profiles/inbox"]', text: 'Inbox')
  end
end
