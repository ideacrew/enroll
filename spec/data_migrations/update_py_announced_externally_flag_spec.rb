require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_py_announced_externally_flag")

describe UpdatePyAnnouncedExternallyFlag do

  let(:given_task_name) { "update_py_announced_externally_flag" }
  subject { UpdatePyAnnouncedExternallyFlag.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating plan year field announced externally", :dbclean => :after_each do

    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let!(:active_plan_year){ FactoryGirl.build(:plan_year,aasm_state:'active', benefit_groups:[benefit_group]) }
    let!(:renewal_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolled") }
    let(:employer_profile){ FactoryGirl.build(:employer_profile, :aasm_state => "binder_paid", plan_years: [active_plan_year]) }
    let!(:organization)  {FactoryGirl.create(:organization,employer_profile:employer_profile)}

    context 'for initial employer' do

      it "should update announced externally field to true" do
        expect(active_plan_year.announced_externally).to be_falsey
        subject.migrate
        active_plan_year.reload
        expect(active_plan_year.announced_externally?).to be_truthy
      end

      it "should update announced externally field to true" do
        active_plan_year.update_attributes(aasm_state:'enrolled')
        expect(active_plan_year.announced_externally).to be_falsey
        subject.migrate
        active_plan_year.reload
        expect(active_plan_year.announced_externally?).to be_truthy
      end

      it "should not update field announced externally" do
        active_plan_year.update_attributes(aasm_state:'enrolling')
        expect(active_plan_year.announced_externally).to be_falsey
        subject.migrate
        active_plan_year.reload
        expect(active_plan_year.announced_externally?).to be_falsey
      end

    end

    context 'for renewal employer' do

      before :each do
        employer_profile.plan_years << renewal_plan_year
      end

      it "should update for active and renewal plan year announced_externally field" do
        expect(active_plan_year.announced_externally).to be_falsey
        expect(renewal_plan_year.announced_externally).to be_falsey
        subject.migrate
        active_plan_year.reload
        renewal_plan_year.reload
        expect(active_plan_year.announced_externally?).to be_truthy
        expect(renewal_plan_year.announced_externally).to be_truthy
      end

      it "should update only for only active plan year announced_externally field" do
        renewal_plan_year.update_attributes(aasm_state:'renewing_enrolling')
        expect(active_plan_year.announced_externally).to be_falsey
        expect(renewal_plan_year.announced_externally).to be_falsey
        subject.migrate
        active_plan_year.reload
        renewal_plan_year.reload
        expect(active_plan_year.announced_externally?).to be_truthy
        expect(renewal_plan_year.announced_externally).to be_falsey
      end

    end
  end
end
