require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_hbx_id")

describe ChangeHbxId do
  let(:given_task_name) { "change_hbx_id" }
  subject { ChangeHbxId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing person hbx id to a specific one" do
    let(:person) { FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("new_hbx_id").and_return("34588973")
      allow(ENV).to receive(:[]).with("action").and_return("change_person_hbx")
    end

    it "should change person hbx id " do
      subject.migrate
      person.reload
      expect(person.hbx_id).to eq "34588973"
    end
  end

  describe "changing person hbx id to a specific one" do
    let(:person) { FactoryGirl.create(:person)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with("new_hbx_id").and_return("")
      allow(ENV).to receive(:[]).with("action").and_return("change_person_hbx")
    end

    it "should change person hbx id " do
      hbx_id = person.hbx_id
      subject.migrate
      person.reload
      expect(person.hbx_id).not_to eq hbx_id
    end
  end

  describe "changing organization hbx id to a specific one" do
    let(:organization) { FactoryGirl.create(:organization)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(organization.hbx_id)
      allow(ENV).to receive(:[]).with("new_hbx_id").and_return("34588973")
      allow(ENV).to receive(:[]).with("action").and_return("change_organization_hbx")
    end

    it "should change organization hbx id " do
      subject.migrate
      organization.reload
      expect(organization.hbx_id).to eq "34588973"
    end
  end

  describe "changing organization hbx id to a specific one" do
    let(:organization) { FactoryGirl.create(:organization)}
    before(:each) do
      allow(ENV).to receive(:[]).with("hbx_id").and_return(organization.hbx_id)
      allow(ENV).to receive(:[]).with("new_hbx_id").and_return("")
      allow(ENV).to receive(:[]).with("action").and_return("change_organization_hbx")

    end

    it "should change organization hbx id " do
      hbx_id = organization.hbx_id
      subject.migrate
      organization.reload
      expect(organization.hbx_id).not_to eq hbx_id
    end
  end
end