require 'rails_helper'
RSpec.describe "exchanges/hbx_profiles/_edit_force_publish", :dbclean => :after_each do
  let!(:organization){ FactoryGirl.create(:organization) }
  let!(:employer_profile) { FactoryGirl.create(:employer_profile, organization: organization)}
  let!(:draft_plan_year) { FactoryGirl.create(:future_plan_year, aasm_state: 'draft', employer_profile: employer_profile) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:person) do
    FactoryGirl.create(:person, :with_hbx_staff_role).tap do |person|
      FactoryGirl.create(:permission, :super_admin).tap do |permission|
        person.hbx_staff_role.update_attributes(permission_id: permission.id)
        person
      end
    end
  end
  let(:params) { {row_actions_id: "family_actions_#{organization.id.to_s}"} }

  before :each do
    assign :organization, organization
    assign :plan_year, draft_plan_year
    render partial: 'exchanges/hbx_profiles/edit_force_publish.html.erb', locals: {params: params}
  end

  context "edit force publish" do
    it "Should match header text Publish Application" do
      expect(rendered).to match(/Publish Application/)
    end
    it "Should match text " do
      expect(rendered).to match(/Application Type/)
      expect(rendered).to match(/Effective Date/)
      expect(rendered).to match(/OE End Date/)
      expect(rendered).to match(/Application Status/)
      expect(rendered).to match(/Submitted At/)
      expect(rendered).to match(/Last Updated At/)
    end
  end
end
