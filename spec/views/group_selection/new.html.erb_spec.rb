require 'rails_helper'

describe "group_selection/new.html.erb" do

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
