require 'rails_helper'

describe "shared/inboxes/_message_list.html.erb" do
  let(:shared_message_properties) do
    {
        :from => "somebody",
        :folder => "Inbox",
        :message_read => false
    }
  end

  let(:message_1) { instance_double(Message, {:id => "11111", :created_at=>TimeKeeper.date_of_record.yesterday}.merge(shared_message_properties)) }
  let(:message_2) { instance_double(Message, {:id => "22222", :created_at=>TimeKeeper.date_of_record.prev_month}.merge(shared_message_properties)) }
  let(:mock_inbox) { instance_double(Inbox, {:messages => [message_1, message_2], :unread_messages => [message_1, message_2], :deleted_messages => []}) }
  let(:mock_provider) { instance_double(EmployerProfile,{:id => "12345", :model_name => EmployerProfile, :inbox => mock_inbox} ) }
  before :each do
    assign(:folder,"Sent")
    assign(:sent_box, true)
    assign(:provider,mock_provider)
    allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true))
    render "insured/families/inbox.html.erb"
  end
  context "when no deleted/archived messages are present" do

    it "should have text From" do
      expect(rendered).to have_content("From")
    end
    it "should not have text FROM" do
      expect(rendered).to_not have_content("FROM")
    end
    it "should not have text Inbox: FROM" do
      expect(rendered).to_not have_content("Inbox: FROM")
    end
    it "should not have text archived" do
      expect(rendered).not_to have_content("Archived")
    end
  end

  context "when there are deleted/archived messages" do
    let(:archived_messages) do
      {
          :from => "somebody",
          :folder => "Deleted",
          :message_read => true
      }
    end
    let(:message_3) { instance_double(Message, {:id => "12324", :created_at=>TimeKeeper.date_of_record.yesterday}.merge(archived_messages)) }
    let(:message_4) { instance_double(Message, {:id => "43849", :created_at=>TimeKeeper.date_of_record.prev_month}.merge(archived_messages)) }
    let(:mock_inbox) { instance_double(Inbox, {:messages => [message_3, message_4], :unread_messages => [message_1, message_2], :deleted_messages => [message_3, message_4]}) }
    let(:mock_provider) { instance_double(EmployerProfile,{:id => "12345", :model_name => EmployerProfile, :inbox => mock_inbox} ) }

    it "should have text archived" do
      expect(rendered).to have_content("Archived")
    end

  end

end
