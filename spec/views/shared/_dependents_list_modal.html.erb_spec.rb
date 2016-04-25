require 'rails_helper'

describe "shared/_dependents_list_modal.html.erb" do
  let(:user) { FactoryGirl.create(:user, person: subscriber) }
  let(:user_two) { FactoryGirl.create(:user, person: dependent_one) }
  let(:user_three) { FactoryGirl.create(:user, person: dependent_two) }
  let(:subscriber) { FactoryGirl.create(:person) }
  let(:dependent_one) { FactoryGirl.create(:person) }
  let(:dependent_two) { FactoryGirl.create(:person) }
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member) }

  before :each do
    allow(subscriber).to receive(:find_relationship_with).and_return('self')
    render partial: "shared/dependents_list_modal", locals: { subscriber: [user], dependents: [user_two, user_three]}
  end

  it "shoud have a table with rows" do
    expect(rendered).to have_selector("tr", count: 4)
  end

end
