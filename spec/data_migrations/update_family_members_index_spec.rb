require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_family_members_index")

describe UpdateFamilyMembersIndex do

  let(:given_task_name) { "update_family_members_index" }
  subject { UpdateFamilyMembersIndex.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "case with if both primary_person and dependent is present" do
    before :each do
      allow(ENV).to receive(:[]).with("primary_hbx").and_return("")
      allow(ENV).to receive(:[]).with("dependent_hbx").and_return("")
    end

    it "found no person with given primary_hbx and dependent_hbx" do
      expect{subject.migrate}.to raise_error("some error person with hbx_id: and hbx_id: not found")
    end

    describe "case with if primary_person has family" do
      before :each do
        allow(ENV).to receive(:[]).with("primary_hbx").and_return("1111")
        allow(ENV).to receive(:[]).with("dependent_hbx").and_return("")
      end
      it "found no family with given dependent_hbx" do
        expect{subject.migrate}.to raise_error("some error person with hbx_id:1111 and hbx_id: not found")
      end
    end

    describe "case with if dependent has family" do
      before :each do
        allow(ENV).to receive(:[]).with("primary_hbx").and_return("")
        allow(ENV).to receive(:[]).with("dependent_hbx").and_return("1112")
      end
      it "found no family with given primary_hbx" do
        expect{subject.migrate}.to raise_error("some error person with hbx_id: and hbx_id:1112 not found")
      end
    end

    describe "case with if primary_person has person_relationships" do
      before :each do
        allow(ENV).to receive(:[]).with("primary_hbx").and_return("1111")
        allow(ENV).to receive(:[]).with("dependent_hbx").and_return("")
      end
      it "found no family with given dependent_hbx" do
        expect{subject.migrate}.to raise_error("some error person with hbx_id:1111 and hbx_id: not found")
      end
    end

    describe "case with if dependent has family" do
      before :each do
        allow(ENV).to receive(:[]).with("primary_hbx").and_return("")
        allow(ENV).to receive(:[]).with("dependent_hbx").and_return("1112")
      end
      it "found no family with given primary_hbx" do
        expect{subject.migrate}.to raise_error("some error person with hbx_id: and hbx_id:1112 not found")
      end
    end
  end

  describe "update family_members index", dbclean: :after_each do

    let(:wife) { FactoryGirl.create(:person, first_name: "wifey")}
    let(:husband) { FactoryGirl.create(:person, first_name: "hubby")}
    let(:family) { FactoryGirl.build(:family) }
    let(:family1) { FactoryGirl.build(:family) }
    let!(:wifes_family) do
      wife.person_relationships << PersonRelationship.new(relative_id: wife.id, kind: "self")
      wife.person_relationships << PersonRelationship.new(relative_id: husband.id, kind: "spouse")
      wife.save

      family.add_family_member(wife, is_primary_applicant: true)
      family.add_family_member(husband)
      family.save
      family
    end

    let!(:husbands_family) do
      husband.person_relationships << PersonRelationship.new(relative_id: husband.id, kind: "self")
      husband.person_relationships << PersonRelationship.new(relative_id: wife.id, kind: "spouse")
      husband.save

      family1.add_family_member(husband, is_primary_applicant: true)
      family1.add_family_member(wife)
      family1.save
      family1
    end

    before(:each) do
      allow(ENV).to receive(:[]).with("primary_id").and_return(wife.id)
      allow(ENV).to receive(:[]).with("dependent_id").and_return(husband.id)
      allow(ENV).to receive(:[]).with("primary_hbx").and_return(wife.hbx_id)
      allow(ENV).to receive(:[]).with("dependent_hbx").and_return(husband.hbx_id)
    end

    it "should swap the index of family members" do
      wife.primary_family.family_members[0].update_attributes(person_id: husband.id)
      wife.primary_family.family_members[1].update_attributes(person_id: wife.id)
      expect(wifes_family.family_members.first.person.first_name).to eq "wifey"
      expect(wifes_family.family_members.second.person.first_name).to eq "hubby"
      subject.migrate
      wifes_family.reload
      expect(wifes_family.family_members.first.person.first_name).to eq "hubby"
      expect(wifes_family.family_members.second.person.first_name).to eq "wifey"
    end

    it "should update the is_primary_applicant" do
      husband.primary_family.family_members[0].update_attributes(is_primary_applicant: true)
      husband.primary_family.family_members[1].update_attributes(is_primary_applicant: false)
      expect(husbands_family.family_members.first.person.first_name).to eq "hubby"
      expect(husbands_family.family_members.second.person.first_name).to eq "wifey"
      subject.migrate
      husbands_family.reload
      expect(husbands_family.family_members.first.person.first_name).to eq "hubby"
      expect(husbands_family.family_members.second.person.first_name).to eq "wifey"
    end
  end
end