require "rails_helper"

describe IvlNotificationMailer do
  describe "new_user" do
    before(:each) do
      @census_employee = FactoryGirl.create(:census_employee)
    end

    let(:mail) { IvlNotificationMailer.lawful_presence_verified(@census_employee) }

    it "renders the headers" do
      mail.subject.should eq("DCHealthLink Notification")
      mail.to.should eq([])
      mail.from.should eq([])
    end

    it "renders the body" do
      mail.body.encoded.should_not be_empty
    end
  end

end
