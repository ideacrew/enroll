require "rails_helper"

RSpec.describe "group_selection/new.html.erb" do
  context "coverage selction" do
    let(:person) { FactoryGirl.create(:person) }
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:family_member1) { double(id: "family_member", primary_relationship: "self", dob: Date.new(1990,10,10), full_name: "member") }
    let(:family_member2) { double(id: "family_member", primary_relationship: "parent", dob: Date.new(1990,10,10), full_name: "member") }
    let(:family_member3) { double(id: "family_member", primary_relationship: "spouse", dob: Date.new(1990,10,10), full_name: "member") }
    let(:coverage_household) { double(family_members: [family_member1, family_member2, family_member3]) }

    before(:each) do
      assign(:person, person)
      assign(:employee_role, employee_role)
      assign(:coverage_household, coverage_household)
      allow(employee_role).to receive(:benefit_group).and_return(benefit_group)
      allow(family_member1).to receive(:is_primary_applicant?).and_return(true)
      allow(family_member2).to receive(:is_primary_applicant?).and_return(false)
      allow(family_member3).to receive(:is_primary_applicant?).and_return(false)

      controller.request.path_parameters[:person_id] = person.id
      controller.request.path_parameters[:employee_role_id] = employee_role.id
      render :template => "group_selection/new.html.erb"
    end

    it "should show the title of family members" do
      expect(rendered).to match /Family Members/
    end

    it "should have three checkbox option" do
      expect(rendered).to have_selector("input[type='checkbox']", count: 3)
    end

    it "should have a checked checkbox option" do
      expect(rendered).to have_selector("input[checked='checked']", count: 2)
    end

    it "should have a disabled checkbox option" do
      expect(rendered).to have_selector("input[disabled='disabled']", count: 1)
    end

    it "should have a readonly checkbox option" do
      expect(rendered).to have_selector("input[readonly='readonly']", count: 1)
    end
  end

  context "family member" do
    def new_benefit_group
      instance_double(
        "BenefitGroup",
        relationship_benefits: new_relationship_benefit
      )
    end

    def new_relationship_benefit
      random_value=rand(999_999_999)
      double(
        "RelationshipBenefit",
        offered: "offered:#{random_value}",
        select: double(map: "test")
      )
    end

    def new_family_member
      random_value=rand(999_999_999)
      instance_double(
        "FamilyMember",
        id: "id_#{random_value}",
        dob: 25.years.ago,
        full_name: "full_name_#{random_value}",
        is_primary_applicant?: true,
        primary_relationship: "self"
      )
    end

    def new_family_member_1
      random_value=rand(999_999_999)
      instance_double(
        "FamilyMember",
        id: "id_#{random_value}",
        dob: 3.years.ago,
        full_name: "full_name_#{random_value}",
        is_primary_applicant?: false,
        primary_relationship: "child"
      )
    end

    let(:family_members){[new_family_member, new_family_member_1]}
    let(:person) { instance_double("Person", id: "Person.id") }
    let(:coverage_household) { instance_double("CoverageHousehold", family_members: family_members) }
    let(:employee_role) { instance_double("EmployeeRole", id: "EmployeeRole.id", benefit_group: new_benefit_group) }

    before :each do
      assign :person, person
      assign :employee_role, employee_role
      assign :coverage_household, coverage_household
      render file: "group_selection/new.html.erb"
    end

    it "should display family members" do
      family_members.each do |member|
        expect(rendered).to match(/#{member.full_name}/m)
      end
    end
  end
end
