require 'rails_helper'

RSpec.describe "consumer_profiles/_menu.html.erb" do
  let(:consumer_role){ double("ConsumerRole") }
  let(:person) {double("Person")}
  let(:inbox) { double("Inbox") }

  before :each do
    assign(:person, person)
    allow(person).to receive(:consumer_role).and_return(consumer_role)
    allow(person).to receive(:inbox).and_return(inbox)
    allow(inbox).to receive(:unread_messages).and_return(3)
    render "consumer_profiles/menu", :active_tab => "home-tab"
  end

  it "should display the main menu" do
    expect(rendered).to have_selector('a[href="/consumer_profiles/personal"]', text: 'Profile')
    expect(rendered).to have_selector('a[href="/consumer_profiles/plans"]', text: 'Plans')
    expect(rendered).to have_selector('a[href="/consumer_profiles/inbox"]', text: 'Inbox')
  end
end
