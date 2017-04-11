require "rails_helper"
include ActionView::Context
RSpec.describe "insured/family_relationships/_form.html.erb" do
  let(:person) { Person.new }
  let(:current_user) {FactoryGirl.create(:user)}
  let(:test_family) {FactoryGirl.create(:family, :with_primary_family_member)}
  let(:relationship_kinds) {PersonRelationship::Relationships}
  let(:child) {FactoryGirl.create(:family_member, :family => test_family)}
  let(:unrelated_member) {FactoryGirl.create(:family_member, :family => test_family)}
  let(:missing_relationships){ [{child.id => unrelated_member.id}]}
  before :each do
    assign(:family, test_family)
    render partial: "insured/family_relationships/form", locals: {form_remote: false, missing_relationships: missing_relationships, relationship_kinds: relationship_kinds, family: test_family, redirect_url: ""}
  end

  it "should have title" do
    expect(rendered).to match /Household Relationships/
  end

  it "should render form with missing relationship questions" do
    expect(rendered).to match /Relationship to/
  end

  it "should not display the message" do
    expect(rendered).not_to match /All the relationships are added/
  end

  it "should display family member's name" do
    child_name = child.person.full_name
    unrelated_name = unrelated_member.person.full_name
    expect(rendered).to match child_name
    expect(rendered).to match unrelated_name
  end

  describe "without any missing relationships for the family" do
    let(:missing_relationships2) {[]}
    before :each do
      render partial: "insured/family_relationships/form", locals: {form_remote: false, missing_relationships: missing_relationships2, relationship_kinds: relationship_kinds, family: test_family, redirect_url: ""}
    end

    it "should display message if all relationships are defined" do
      expect(rendered).to match /Household Relationships/
      expect(rendered).to match /All the relationships are added/
    end
  end
end
