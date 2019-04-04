require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_user_record")

describe RemoveUserRecord, dbclean: :after_each do

  let(:given_task_name) { "remove_user_record" }
  subject { RemoveUserRecord.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "deleting user record" do
    let(:person) { FactoryBot.create(:person)}
    let(:user) { FactoryBot.create(:user, person: person) }
    before(:each) do
      allow(person).to receive(:user).and_return(user)
    end

    it "should remove user record" do
      ClimateControl.modify hbx_id: person.hbx_id do 
        subject.migrate
        person.reload
        expect(Person.where(hbx_id: person.hbx_id).first.user).to eq nil
      end
    end
  end
end
