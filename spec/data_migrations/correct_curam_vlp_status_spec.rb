require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_curam_vlp_status")

describe CorrectCuramVlpStatus do
  describe "given a task name" do
    let(:given_task_name) { "migrate_my_curam_vlp_status" }
    subject { CorrectCuramVlpStatus.new(given_task_name, double(:current_scope => nil)) }

    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "given a person who has a vlp authority of 'curam', in the 'pending' status" do
    subject { CorrectCuramVlpStatus.new("fix me task", double(:current_scope => nil)) }
    let(:curam_user) { FactoryGirl.create(:person, :with_consumer_role)}

    before :each do
      curam_user.consumer_role.lawful_presence_determination.vlp_authority = "curam"
      curam_user.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
      curam_user.consumer_role.aasm_state = "verification_outstanding"
      curam_user.save!
      subject.migrate
    end
    it "moves the person to 'fully verified'" do
      curam_user.reload
      expect(curam_user.consumer_role.lawful_presence_determination.vlp_authority).to eq "curam"
      expect(curam_user.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_successful"
      expect(curam_user.consumer_role.aasm_state).to eq "fully_verified"
    end
  end

  describe "given a person who has a vlp authority of 'ssa', in the 'pending' status" do
    subject { CorrectCuramVlpStatus.new("fix me task", double(:current_scope => nil)) }
    let(:user) { FactoryGirl.create(:person, :with_consumer_role)}

    before :each do
      user.consumer_role.lawful_presence_determination.vlp_authority = "ssa"
      user.consumer_role.lawful_presence_determination.aasm_state = "verification_pending"
      user.consumer_role.aasm_state = "verification_outstanding"
      user.save!
      subject.migrate
    end
    it "does not change the state of the person"do
      user.reload
      expect(user.consumer_role.lawful_presence_determination.vlp_authority).to eq "ssa"
      expect(user.consumer_role.lawful_presence_determination.aasm_state).to eq "verification_pending"
      expect(user.consumer_role.aasm_state).to eq "verification_outstanding"
    end
  end
end
