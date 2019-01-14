require "rails_helper"

describe IvlNotificationMailer do
  # describe "new_user" do
  #   let(:consumer_role) {FactoryBot.create(:consumer_role)}
  #   let(:family) {FactoryBot.build(:family, :with_primay_family_member)}
  #   let(:hbx_enrollment) {double(plan: double(name: 'plan name'), total_premium: 100, phone_number: '123456789', hbx_enrollment_members: [], effective_on: TimeKeeper.date_of_record)}
  #   let(:hbx_enrollments) {double(active: [hbx_enrollment])}
  #   let(:household) {double(hbx_enrollments: hbx_enrollments)}

  #   before(:each) do
  #     @census_employee = consumer_role
  #     allow(Family).to receive(:find_by_primary_applicant).and_return family
  #     allow(family).to receive(:latest_household).and_return household
  #     allow(household).to receive(:hbx_enrollments).and_return hbx_enrollments
  #   end

  #   context "lawful_presence_verified" do
  #   let(:mail) { IvlNotificationMailer.lawful_presence_verified(@census_employee) }

  #   it "renders the headers" do
  #     mail.subject.should eq("DCHealthLink Notification")
  #     mail.to.should eq([consumer_role.email.address])
  #     mail.from.should eq(["no-reply@shop.dchealthlink.com"])
  #   end
   
  #   it "renders the body" do
  #     mail.body.encoded.should_not be_empty
  #     mail.body.parts.length.should eq(2)
  #     mail.body.parts.collect(&:content_type).should == ["text/html; charset=UTF-8", "application/pdf; charset=UTF-8; filename=notice.pdf"]
  #     mail.attachments.size.should eq(1)
  #     attachment = mail.attachments[0]
  #     attachment.should be_a_kind_of(Mail::Part)
  #     attachment.content_type.should be_start_with('application/pdf;')
  #     attachment.filename.should == 'notice.pdf'
  #     # email.body.encoded.should include(link_to("click here", :controller => "ivl_notifications").to_html)
  #   end
  #   end
    
  #   context "lawful_presence_unverified" do
  #   let(:mail) { IvlNotificationMailer.lawful_presence_unverified(@census_employee) }
    
  #   it "renders the headers" do
  #     mail.subject.should eq("DCHealthLink Notification")
  #     mail.to.should eq([consumer_role.email.address])
  #     mail.from.should eq(["no-reply@shop.dchealthlink.com"])
  #   end
   
  #   it "renders the body" do
  #     mail.body.encoded.should_not be_empty
  #     mail.body.parts.length.should eq(2)
  #     mail.body.parts.collect(&:content_type).should == ["text/html; charset=UTF-8", "application/pdf; charset=UTF-8; filename=notice.pdf"]
  #     mail.attachments.size.should eq(1)
  #     attachment = mail.attachments[0]
  #     attachment.should be_a_kind_of(Mail::Part)
  #     attachment.content_type.should be_start_with('application/pdf;')
  #     attachment.filename.should == 'notice.pdf'
  #   end
  #   end
    
  #   context "lawfully_ineligible" do
  #   let(:mail) { IvlNotificationMailer.lawfully_ineligible(@census_employee) }
    
  #   it "renders the headers" do
  #     mail.subject.should eq("DCHealthLink Notification")
  #     mail.to.should eq([consumer_role.email.address])
  #     mail.from.should eq(["no-reply@shop.dchealthlink.com"])
  #   end
   
  #   it "renders the body" do
  #     mail.body.encoded.should_not be_empty
  #     mail.body.parts.length.should eq(2)
  #     mail.body.parts.collect(&:content_type).should == ["text/html; charset=UTF-8", "application/pdf; charset=UTF-8; filename=notice.pdf"]
  #     mail.attachments.size.should eq(1)
  #     attachment = mail.attachments[0]
  #     attachment.should be_a_kind_of(Mail::Part)
  #     attachment.content_type.should be_start_with('application/pdf;')
  #     attachment.filename.should == 'notice.pdf'
  #   end
  #   end
    
  # end

end
