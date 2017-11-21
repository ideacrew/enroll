require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "move_phone_between_two_people")

describe MovePhoneBetweenTwoPeople do
  let(:given_task_name) { "move_phone_between_two_people" }
  subject { MovePhoneBetweenTwoPeople.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "move phone between two people" do
    let!(:person1) { FactoryGirl.create(:person, :with_work_phone)}
    let!(:person2) { FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("from_hbx_id").and_return(person1.hbx_id)
      allow(ENV).to receive(:[]).with("to_hbx_id").and_return(person2.hbx_id)
    end

    it "add phones to person 2" do
      person1_phone_before=person1.phones.size
      person2_phone_before=person2.phones.size
      subject.migrate
      person1.reload
      person2.reload
      expect(person2.phones.size).to eq person1_phone_before+person2_phone_before
      expect(person1.phones.size).to eq 0
    end
  end
end