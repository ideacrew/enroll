# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('spec/shared_contexts/enrollment.rb')

describe 'rake renewal_state_change:ivl_users',type: :task, :dbclean => :around_each, :if => (EnrollRegistry[:enroll_app].setting(:site_key).item.to_s == "dc") do
  include_context "setup families enrollments"

  before :all do
    Rake.application.rake_require "tasks/renewal_state_change"
    Rake::Task.define_task(:environment)
  end

  after :each do
    FileUtils.rm_rf(Dir["#{Rails.root}/public/ivl_state_changed_users.csv"])
  end

  it "should update aasmstate" do
    expect(family_unassisted.reload.active_household.hbx_enrollments.map(&:aasm_state)).to include("renewing_coverage_selected")
    Rake::Task["renewal_state_change:ivl_users"].invoke
    expect(family_unassisted.reload.active_household.hbx_enrollments.map(&:aasm_state)).not_to include("renewing_coverage_selected")
  end

  it "should create work flow state transition" do
    Rake::Task["renewal_state_change:ivl_users"].execute
    enrollment = family_unassisted.reload.active_household.hbx_enrollments.select {|hbx_enroll| hbx_enroll.workflow_state_transitions.present?}
    expect(enrollment.first.workflow_state_transitions.first).not_to be nil
    expect(enrollment.first.workflow_state_transitions.first.event).to eq "begin_coverage!"
    expect(enrollment.first.workflow_state_transitions.first.from_state).to eq "renewing_coverage_selected"
    expect(enrollment.first.workflow_state_transitions.first.to_state).to eq "coverage_selected"
  end
end
