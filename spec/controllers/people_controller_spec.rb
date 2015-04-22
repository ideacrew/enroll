require 'rails_helper'

RSpec.describe PeopleController, :kind => :controller do
  describe "family members" do 
    login_user
    include_context "BradyBunch" 
    let(:organization) { FactoryGirl.create(:organization, legal_name: "Kaiser Permanente, Inc.", dba: "Kaiser") }
    let(:person) { mike }
    let(:employee) {FactoryGirl.create(:employee_role, person: person)}
    let(:family) { mikes_family }
    let(:family_member) {FactoryGirl.create(:family_member, family: family, person_id: person.id, is_primary_applicant: true)}

    it "add dependents" do
      post :add_dependents, person_id: person.id, organization_id: organization.id, format: 'js'
      expect(assigns(:dependent).family).to  eq  family
    end

    it "save dependents" do
      fm_count = family.family_members.count
      pr_count = person.person_relationships.count
      post :save_dependents,
        person: person.id,
        employer: organization.id,
        family_member: {id: "5528968763686937b3000011",
                        primary_relationship: "child",
                        first_name: "jack",
                        last_name: "White",
                        dob: "01/04/2014",
                        ssn: "123456789",
                        gender: "male"},
        format: 'js'
      family.reload
      person.reload
      expect(family.family_members.count).to eq fm_count+1
      expect(person.person_relationships.count).to eq pr_count+1
      expect(controller.flash.now[:notice]).to  eq  "Family Member Added."
    end

    it "save dependents failed when new family member" do
      fm_count = family.family_members.count
      pr_count = person.person_relationships.count
      post :save_dependents,
        person: person.id,
        employer: organization.id,
        family_member: {id: "5528968763686937b3000011",
                        primary_relationship: "child",
                        dob: "01/04/2014",
                        ssn: "123456789",
                        gender: "male"},
        format: 'js'
      family.reload
      person.reload
      expect(family.family_members.count).to eq fm_count
      expect(person.person_relationships.count).to eq pr_count
      expect(controller.flash.now[:error_msg]).to start_with "Error in Family Member Addition."
    end

    it "remove_dependents successful" do
      family_member
      count = family.family_members.count
      delete :remove_dependents,
        id: family_member.id,
        person_id: person.id,
        organization_id: organization.id,
        format: 'js'
      family.reload
      expect(family.family_members.count).to eq count-1
    end
  end
end
