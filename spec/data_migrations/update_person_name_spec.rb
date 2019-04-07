require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_person_name")
describe UpdatePersonName, dbclean: :after_each do
  let(:given_task_name) { "update_person_name" }
  subject { UpdatePersonName.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "changing person's name" do
    let!(:person) { FactoryBot.create(:person, first_name: 'James', last_name: 'federer')}

    it "should change name of the person" do
      person.reload
      ClimateControl.modify(
        hbx_id: person.hbx_id,
        first_name: 'Chirec',
        last_name: 'Yuin'
      ) do
        subject.migrate
        person.reload
        expect(person.first_name).to eq 'Chirec'
        expect(person.last_name).to eq 'Yuin'
      end
    end
  end
end
