require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_ivl_user_dependent")
describe AddIvlUserDependent do
  describe "given a task name" do
	let(:given_task_name) { "add_ivl_user_dependent" }
	subject { AddIvlUserDependent.new(given_task_name, double(:current_scope => nil)) }

	it "has the given task name" do
	  expect(subject.name).to eql given_task_name
	end
  end

  describe "add coverage household member" do
  	subject { AddIvlUserDependent.new("add_ivl_user_dependent", double(:current_scope => nil)) }
  	context "adding coverage household" do
	  let(:family) { FactoryGirl.build(:family) }
	  let(:family_member)  { FactoryGirl.create(:person)}
	  let(:person) do
	    p = FactoryGirl.build(:person, first_name: ENV['first_name'], last_name: ENV['last_name'], dob: ENV['dob'])
	    p.person_relationships.build(relative: family_member, kind: "domestic_partner")
	    p.save
	    p
	  end
	  before(:each) do
	  	allow(ENV).to receive(:[]).with("first_name").and_return("test")
	  	allow(ENV).to receive(:[]).with("last_name").and_return("test")
	  	allow(ENV).to receive(:[]).with("dob").and_return("01/01/1984")
	    f_id = family.id
	    family.add_family_member(person, is_primary_applicant: true)
	    family.relate_new_member(family_member, "domestic_partner")
	    family.save!
	    subject.migrate
	    family.reload
	  end

	  it "should add coverage household record" do
        immediate_coverage_members = family.active_household.immediate_family_coverage_household.coverage_household_members
        expect(immediate_coverage_members.length).to eq 2
	  end

  	end

   
  end
end