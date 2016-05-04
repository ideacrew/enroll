require 'rails_helper'
describe "shared/_tab_panel.html.erb" do
  before :each do
    render template: "shared/_tab_panel.html.erb"
  end

  it "should display the link of announcement" do
    expect(rendered).to have_selector('a', text: 'Announcements')
  end
end
