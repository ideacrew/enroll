require 'rails_helper'

describe "exchanges/agents/_primary_nav.html.erb" do
    let(:person) { FactoryBot.create(:person, csr_role: nil)}
    let(:current_user) { FactoryBot.create(:user, :person => person)}
    let(:active_tab) {"home-tab"}
    let(:csr_role) { FactoryBot.build(:csr_role, cac: false) }
    let(:cac_role) { FactoryBot.build(:csr_role, cac: true) }
    before :each do
      @unread_messages = 38
      allow(current_user).to receive(:person).and_return(person)
      sign_in(current_user)
    end

    it "renders the toolbar template for CSRs" do
      allow(person).to receive(:csr_role).and_return(csr_role)
      render "exchanges/agents/primary_nav", :active_tab => "home-tab"
      expect(rendered).to have_text(/Families/)
      expect(rendered).to have_text(/Inbox/)
      expect(rendered).to have_text(@unread_messages)
    end
end    
