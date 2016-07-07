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

    it "moves the person to 'fully verified'"
  end

  describe "given a person who has a vlp authority of 'ssa', in the 'pending' status" do
    subject { CorrectCuramVlpStatus.new("fix me task", double(:current_scope => nil)) }
    it "does not change the state of the person"
  end
end
