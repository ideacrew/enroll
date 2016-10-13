require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "terminate_census_employee")

describe TerminateCensusEmployee do

  describe "given a task name" do
    let(:given_task_name) { "termiante_census_employee" }
    subject { TerminateCensusEmployee.new(given_task_name, double(:current_scope => nil)) }

    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
end
