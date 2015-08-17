require "rails_helper"

describe IvlNotificationMailer do
  describe "new_user" do
    before(:each) do
      @census_employee = FactoryGirl.create(:census_employee)
    end

    let(:mail) { IvlNotificationMailer.lawful_presence_verified(@census_employee) }

    it "renders the headers" do
      mail.subject.should eq("DCHealthLink Notification")
      mail.to.should eq(["example1@example.com"])
      mail.from.should eq(["no-reply@shop.dchealthlink.com"])
    end
   
    it "renders the body" do
      mail.body.encoded.should_not be_empty
      mail.body.parts.length.should eq(2)
      mail.body.parts.collect(&:content_type).should == ["text/html; charset=UTF-8", "application/pdf; charset=UTF-8; filename=notice.pdf"]
      mail.attachments.size.should eq(1)
      attachment = mail.attachments[0]
      attachment.should be_a_kind_of(Mail::Part)
      attachment.content_type.should be_start_with('application/pdf;')
      attachment.filename.should == 'notice.pdf'
      # email.body.encoded.should include(link_to("click here", :controller => "ivl_notifications").to_html)
    end
    
    let(:mail) { IvlNotificationMailer.lawful_presence_unverified(@census_employee) }
    
    it "renders the headers" do
      mail.subject.should eq("DCHealthLink Notification")
      mail.to.should eq(["example3@example.com"])
      mail.from.should eq(["no-reply@shop.dchealthlink.com"])
    end
   
    it "renders the body" do
      mail.body.encoded.should_not be_empty
      mail.body.parts.length.should eq(2)
      mail.body.parts.collect(&:content_type).should == ["text/html; charset=UTF-8", "application/pdf; charset=UTF-8; filename=notice.pdf"]
      mail.attachments.size.should eq(1)
      attachment = mail.attachments[0]
      attachment.should be_a_kind_of(Mail::Part)
      attachment.content_type.should be_start_with('application/pdf;')
      attachment.filename.should == 'notice.pdf'
    end
    
    let(:mail) { IvlNotificationMailer.lawfully_ineligible(@census_employee) }
    
    it "renders the headers" do
      mail.subject.should eq("DCHealthLink Notification")
      mail.to.should eq(["example5@example.com"])
      mail.from.should eq(["no-reply@shop.dchealthlink.com"])
    end
   
    it "renders the body" do
      mail.body.encoded.should_not be_empty
      mail.body.parts.length.should eq(2)
      mail.body.parts.collect(&:content_type).should == ["text/html; charset=UTF-8", "application/pdf; charset=UTF-8; filename=notice.pdf"]
      mail.attachments.size.should eq(1)
      attachment = mail.attachments[0]
      attachment.should be_a_kind_of(Mail::Part)
      attachment.content_type.should be_start_with('application/pdf;')
      attachment.filename.should == 'notice.pdf'
    end
    
    
  end

end
