require 'rails_helper'

RSpec.describe "hbx_admin/_edit_aptc_csr", :dbclean => :after_each do
  let(:organization){  FactoryGirl.create(:organization) }
  let(:new_invalid_fein) { "234-839" }
  let(:org_params) {
    {
      "organization" => { "new_fein" => new_invalid_fein }
    }
  }
  let(:error_messages) {
    {:fein=> ["#{new_invalid_fein} is not a valid FEIN"]}
  }

  before :each do
    assign :organization, organization
  end

  context "change fein" do
    it "Should display the Change FEIN text" do
      render partial: 'exchanges/hbx_profiles/edit_fein.html.erb', locals: {params: org_params }
      expect(rendered).to match(/Change FEIN/)
      expect(rendered).to match(/New FEIN :/)
    end

    it "Should display the error: FEIN must be at least 9 digits" do
      assign :errors_on_save, error_messages
      render partial: 'exchanges/hbx_profiles/edit_fein.html.erb', locals: {params: org_params }
      expect(rendered).to match(/FEIN must be at least 9 digits/)
    end
  end
end
