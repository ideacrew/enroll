require "rails_helper"
include ActionView::Context
RSpec.describe "insured/consumer_roles/_form.html.erb" do
  context "Hbx Admin shows application type field in Persnoa Information Page" do
    binding.pry
    let(:person) { FactoryGirl.create(:person) }
    let!(:person2) { FactoryGirl.create(:person, :with_consumer_role) }
    let!(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person2) }
    let(:current_user) {FactoryGirl.create(:user, :hbx_staff, person: person)}
    before :each do
      @person = person2
      sign_in current_user
      helper = Object.new.extend ActionView::Helpers::FormHelper
      helper.extend ActionDispatch::Routing::PolymorphicRoutes
      helper.extend ActionView::Helpers::FormOptionsHelper
      @person.build_consumer_role if @person.consumer_role.blank?
      @person.consumer_role.build_nested_models_for_person
      mock_form = ActionView::Helpers::FormBuilder.new(:person, @person, helper, {})
      stub_template "shared/_consumer_fields.html.erb" => ''
      allow(view).to receive(:policy_helper).and_return(double("FamilyPolicy", updateable?: true))
      assign(:consumer_role, @person.consumer_role)
      assign(:person, @person)
      render partial: "insured/consumer_roles/form", locals: {f: mock_form}
    end

    it "should display the label text Application Type" do
      binding.pry
      expect(rendered).to match /Application Type :/
    end

    it "should display only 'curam' if user is accociated with e_case_id" do
      expect(rendered).to have_select("person[application_type]")
      expect(rendered).to match /Phone/
    end

  end
end
