require "rails_helper"

RSpec.describe "consumer/consumer_roles/edit.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:consumer_role) { double("ConsumerRole", id: "test")}

  before :each do
    assign(:person, person)
    allow(person).to receive(:consumer_role).and_return(consumer_role)
    render template: "consumer/consumer_roles/edit.html.erb"
  end

  it "should display the page info" do
    expect(rendered).to match(/Let’s begin by entering your personal information. This will take approximately 10 minutes. When you finish, select CONTINUE./)
    expect(rendered).to have_selector('h3', text: 'Enroll - let\'s get you signed up for healthcare')
  end
end
