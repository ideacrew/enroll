require 'rails_helper'

describe "insured/family_members/index.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:family) { Family.new }
  let(:family_member) { family.family_members.new }
  let(:dependent) { Forms::FamilyMember.new(family_id: family.id) }

  before :each do
    sign_in user
    assign :person, person
    assign :family, family
    render template: "insured/family_members/index.html.erb"
  end

  it "should have title" do
    expect(rendered).to have_selector("h3", text: 'Family Members')
  end

  it "should have memo to indicate required fields" do
    expect(rendered).to have_selector('p.memo', text: '* = required field')
  end
end
