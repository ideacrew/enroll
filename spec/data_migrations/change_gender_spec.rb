require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_gender")

describe ChangeGender, dbclean: :after_each do

  let(:given_task_name) { "change_gender" }
  subject { ChangeGender.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing gender for an person with employee role", dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person, gender: "male") }
    let(:employer_profile) { FactoryGirl.create(:employer_profile)}
    let(:census_employee) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, gender: "male") }

    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("ce_id").and_return(census_employee.id)
      allow(ENV).to receive(:[]).with("gender").and_return("female")
    end

    it "should change the gender" do
      subject.migrate
      census_employee.reload
      person.reload
      expect(census_employee.gender).to eq "female"
      expect(person.gender).to eq "female"
    end
  end

  describe "changing gender for a person without employee role ", dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person, gender: "male") }
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("ce_id").and_return("")
      allow(ENV).to receive(:[]).with("gender").and_return("female")
    end

    it "should change the gender" do
      subject.migrate
      person.reload
      expect(person.gender).to eq "female"
    end
  end
  describe "do not change gender for an invalid person input", dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person, gender: "male") }
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return("")
      allow(ENV).to receive(:[]).with("ce_id").and_return("")
      allow(ENV).to receive(:[]).with("gender").and_return("female")
    end
    it "should change the gender" do
      subject.migrate
      person.reload
      expect(person.gender).to eq "male"
    end
  end
end
