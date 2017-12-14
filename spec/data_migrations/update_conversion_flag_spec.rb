require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_conversion_flag")

describe UpdateConversionFlag, dbclean: :after_each do

  let(:given_task_name) { "update_conversion_flag" }
  subject { UpdateConversionFlag.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating conversion flag of employer" do
    let(:employer_profile) { FactoryGirl.create(:employer_profile, profile_source: "conversion")}
    let(:conversion_employer_profile) { FactoryGirl.create(:employer_profile, profile_source: "self_serve")}

    it "should update conversion flag to self_serve" do
      ENV["fein"] = employer_profile.fein
      ENV["profile_source"] = "self_serve"
      subject.migrate
      employer_profile.organization.reload
      expect(employer_profile.organization.employer_profile.profile_source).to eq ("self_serve")
    end

    it "should update the conversion flag to conversion" do
      ENV["fein"] = conversion_employer_profile.fein
      ENV["profile_source"] = "conversion"
      subject.migrate
      employer_profile.organization.reload
      expect(employer_profile.organization.employer_profile.profile_source).to eq ("conversion")
    end
  end
end
