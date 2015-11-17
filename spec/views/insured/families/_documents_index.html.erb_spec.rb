require 'rails_helper'

RSpec.describe "insured/families/_documents_index.html.erb" do
  let(:consumer_role) { FactoryGirl.build(:consumer_role) }
  let(:person) { FactoryGirl.build(:person, consumer_role: consumer_role) }
  let(:family) { FactoryGirl.build(:family, :with_primary_family_member) }
  let(:family_member) { family.family_members.last }

  before :each do
    assign :family_members, [family_member]
    assign :person, person
    assign :time_to, TimeKeeper.date_of_record
  end

  it "should show the state of consumer_role" do
    allow(family_member).to receive(:person).and_return person
    allow(view).to receive(:show_consumer_role_state).and_return "Verified"
    allow(person).to receive(:created_at).and_return TimeKeeper.date_of_record
    render file: "insured/families/_documents_index.html.erb"
    expect(rendered).to have_content "Verified"
  end
end
