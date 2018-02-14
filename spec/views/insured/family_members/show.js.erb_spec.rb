require 'rails_helper'

describe "insured/family_members/show.js.erb" do
  before(:each) do
    allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
  end
  let!(:person) { FactoryGirl.create(:person) }
  let!(:user) { FactoryGirl.create(:user, person: person) }
  let!(:family) { FactoryGirl.create(:family, :with_primary_family_member) }
  let!(:family_member) { FactoryGirl.create(:family_member, family: family, person: person) }
  let!(:dependent) {Forms::FamilyMember.find(family_member.id)}
  let!(:household) { family.active_household }

  context "render show by creat" do
    before :each do
      sign_in user
      assign(:person, person)
      assign(:created, true)
      assign(:dependent, dependent)
      assign(:family, family)
      allow(FamilyMember).to receive(:find).with(family_member.id).and_return(family_member)
      allow(family_member).to receive(:primary_relationship).and_return("self")
      allow(family_member).to receive(:person).and_return person
      allow(person).to receive(:has_mailing_address?).and_return false
      allow(dependent).to receive(:family_member).and_return family_member
      @request.env['HTTP_REFERER'] = 'consumer_role_id'

      stub_template "insured/family_members/dependent" => ''
    end

    it "should display notice when these are no FAAs are present" do
      render file: "insured/family_members/show.js.erb"
      expect(rendered).to match /qle_flow_info/
      expect(rendered).to match /removeClass/
      expect(rendered).to match /hidden/
    end

    it "should render faa_popup when these are FAAs are present in draft" do
      application = FactoryGirl.create(:application, family: family, aasm_state: "draft")
      controller.stub(:action_name).and_return('create')
      render file: "insured/family_members/show.js.erb"
      expect(view).to render_template("insured/family_members/_dependent")
      expect(view).to render_template("insured/families/_faa_popup")
      expect(view).to render_template("insured/family_members/show.js.erb")
    end

    it "should not render faa_popup when these are FAAs are present other than draft" do
      application = FactoryGirl.create(:application, family: family, aasm_state: "submitted")
      controller.stub(:action_name).and_return('create')
      render file: "insured/family_members/show.js.erb"
      expect(view).to render_template("insured/family_members/_dependent")
      expect(view).not_to render_template("insured/families/_faa_popup")
      expect(view).to render_template("insured/family_members/show.js.erb")
    end

  end
end
