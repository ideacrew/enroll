require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "link_user_and_person")

describe LinkUserAndPerson do

  let(:given_task_name) { "link_user_and_person" }
  let!(:person) { FactoryGirl.create(:person)}
  let!(:user) {FactoryGirl.create(:user)}

  subject { LinkUserAndPerson.new(given_task_name, double(:current_scope => nil)) }

  before(:each) do
    allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
    allow(ENV).to receive(:[]).with("user_id").and_return(user.id)
  end

  it "should link the person from user" do
    expect(person.user).to eq nil
    subject.migrate
    person.reload
    expect(person.user).not_to eq nil
  end
end
