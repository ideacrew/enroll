require 'rails_helper'

RSpec.describe FinancialAssistance::ApplicationsController, type: :controller do
  let(:person) { FactoryGirl.create(:person)}
  let(:user) { FactoryGirl.create(:user, :person=>person); }

  describe "GET index" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member,person: person) }

    before(:each) do
      sign_in user
      allow(person).to receive(:primary_family).and_return(family)
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
    end

    it "assigns @applications" do
      application = person.primary_family.applications.new
      application.populate_applicants_for(person.primary_family)
      application.save!
      get :index
      expect(assigns(:applications)).to eq([application])
    end

    it "renders the index template" do
      get :index
      expect(response).to render_template("index")
    end
  end

  context "copy an application" do
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person) }
    let(:primary_member) {family.primary_applicant.person}
    let(:spouse) {FactoryGirl.create(:family_member, family: family).person}
    let(:child) {FactoryGirl.create(:family_member, family: family).person}
    let(:unrelated_member) {FactoryGirl.create(:family_member, family: family).person}

    let(:application) { FactoryGirl.create :application, family: family, aasm_state: 'determined' }

    before(:each) do
      sign_in user
      allow_any_instance_of(FinancialAssistance::Application).to receive(:set_benchmark_plan_id)
      spouse.add_relationship(primary_member, "spouse", family.id)
      primary_member.add_relationship(spouse, "spouse", family.id)
      child.add_relationship(primary_member, "child", family.id)
      primary_member.add_relationship(child, "parent", family.id)
      child.add_relationship(spouse, "child", family.id)
      spouse.add_relationship(child, "parent", family.id)
      unrelated_member.add_relationship(primary_member, "unrelated", family.id)
      primary_member.add_relationship(unrelated_member, "unrelated", family.id)
      family.build_relationship_matrix
      
      get :copy, :id => application.id
    end

    it "redirects to the new application copy" do
      expect(response).to redirect_to(edit_financial_assistance_application_path(assigns(:application).reload))
    end

    it "copies the application's primary application id" do
      draft_application = assigns(:application)
      original_primary_applicant = application.family.family_members.find_by(:is_primary_applicant => true)
      copied_primary_applicant = draft_application.family.family_members.find_by(:is_primary_applicant => true)
      expect(original_primary_applicant.id).to eq (copied_primary_applicant.id)
    end

    it "copies the application's primary_member - spouse relationship as spouse" do
      expect(assigns(:application).family.find_existing_relationship(primary_member.id, spouse.id, family.id)).to eq "spouse"
    end

    it "copies the application's spouse - primary_member relationship as spouse" do
      expect(assigns(:application).family.find_existing_relationship(spouse.id, primary_member.id, family.id)).to eq "spouse"
    end

    it "copies the application's primary member - child relationship as parent" do
      expect(assigns(:application).family.find_existing_relationship(primary_member.id, child.id, family.id)).to eq "parent"
    end

    it "copies the application's child - primary_member relationship as child" do
      expect(assigns(:application).family.find_existing_relationship(child.id, primary_member.id, family.id)).to eq "child"
    end

    it "copies the application's spouse - child relationship as parent" do
      expect(assigns(:application).family.find_existing_relationship(spouse.id, child.id, family.id)).to eq "parent"
    end

    it "copies the application's child - spouse relationship as child" do
      expect(assigns(:application).family.find_existing_relationship(child.id, spouse.id, family.id)).to eq "child"
    end

    it "copies the application's primary_member - unrelated_member relationship as unrelated" do
      expect(assigns(:application).family.find_existing_relationship(primary_member.id, unrelated_member.id, family.id)).to eq "unrelated"
    end

    it "copies the application's unrelated_member - primary_member relationship as unrelated" do
      expect(assigns(:application).family.find_existing_relationship(unrelated_member.id, primary_member.id, family.id)).to eq "unrelated"
    end
  end
end