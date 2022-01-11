require 'rails_helper'

RSpec.describe "insured/families/_navigate_to_curam_for_documents.html.erb" do

  context 'Person with consumer_role' do
    let(:person) {FactoryBot.create(:person)}

    before :each do
      render partial: 'insured/families/navigate_to_curam_for_documents', locals: {display_text: "If you applied for Medicaid and tax credit savings, view additional documents" }
    end

    it "should have text" do
      expect(rendered).to have_content(l10n("insured.families.medicaid_and_tax_credits"))
    end

    it "should have a link" do
      expect(rendered).to have_link(l10n("insured.families.medicaid_and_tax_credits"))
    end

    it "should have text for documents" do
      expect(rendered).to have_content("If you applied for Medicaid and tax credit savings, view additional documents")
    end
  end
end
