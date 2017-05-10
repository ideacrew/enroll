require 'rails_helper'

describe "insured/family_members/_dependent.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:family) { Family.new }
  let(:family_member) { family.family_members.new }
  let(:dependent) { Forms::FamilyMember.new(family_id: family.id) }
  let(:employee_role) { FactoryGirl.build(:employee_role) }
  let(:address) {FactoryGirl.build(:address)}

  before :each do
    sign_in user
    allow(view).to receive(:edit_insured_family_member_path).and_return "#"
    allow(view).to receive(:dependent_valid?).and_return true
  end

  it "should have name" do
    render "insured/family_members/dependent", dependent: dependent, person: person, consumer: person.consumer_role
    expect(rendered).to have_selector("label", text: 'FIRST NAME')
    expect(rendered).to have_selector("label", text: 'LAST NAME')
  end

  it "should have address" do
    allow(view).to receive(:get_address_from_dependent).with(dependent).and_return [address]
    render "insured/family_members/dependent", dependent: dependent, person: person, consumer: person.consumer_role
    expect(rendered).to have_selector("label", text: 'ADDRESS LINE 1')
    expect(rendered).to have_selector("label", text: 'ADDRESS LINE 2')
    expect(rendered).to have_selector("label", text: 'CITY')
    expect(rendered).to have_selector("label", text: 'STATE')
    expect(rendered).to have_selector("label", text: 'ZIP')
  end
end
