require 'rails_helper'

describe "shared/inboxes/_message_list.html.erb" do
  let(:employer_profile) { FactoryGirl.create(:employer_profile, :with_full_inbox) }
  before :each do
    employer_profile.inbox.messages.first.update_attributes(:created_at=>DateTime.new(2016,10,10))
    employer_profile.inbox.messages.last.update_attributes(:created_at=>DateTime.new(2016,11,10))

    render "shared/inboxes/message_list.html.erb", :folder => "Sent", :sent_box => true, :provider => employer_profile
  end

  it "should have text From" do
    expect(rendered).to have_content("From")
  end
  it "should not have text FROM" do
    expect(rendered).to_not have_content("FROM")
  end
  it "should not have text Inbox: FROM" do
    expect(rendered).to_not have_content("Inbox: FROM")
  end
end
