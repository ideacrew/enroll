require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_conversion_flag")

describe UpdateConversionFlag, :dbclean => :after_each do

  let(:given_task_name) { "update_conversion_flag" }
  subject { UpdateConversionFlag.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating conversion flag of employer" do
    let!(:employer_profile) { FactoryGirl.create(:employer_profile,legal_name:'tyutuyyuyutuytuytyu')}

    it "should update profile source to self_serve and shouldn't approve employer attestation" do
      ENV["fein"] = employer_profile.fein
      ENV["profile_source"] = "self_serve"
      subject.migrate
      employer_profile.reload
      expect(employer_profile.profile_source).to eq "self_serve"
      expect(employer_profile.employer_attestation.aasm_state).to eq "approved"
    end

    it "should update profile source to conversion and approve employer attestation" do
      ENV["fein"] = employer_profile.fein
      ENV["profile_source"] = "conversion"
      subject.migrate
      employer_profile.reload
      expect(employer_profile.profile_source).to eq "conversion"
      expect(employer_profile.employer_attestation.aasm_state).to eq "approved"
    end
  end
end
