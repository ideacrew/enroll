require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "fix_special_enrollment_period.rb")

describe FixSpecialEnrollmentPeriod do
  let(:given_task_name) { "fix_special_enrollment_period" }
  subject { FixSpecialEnrollmentPeriod.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "fix sep invalid records" do
    let(:person) { FactoryGirl.create(:person)}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person)}

    before(:each) do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.hbx_id)
      sep = FactoryGirl.build(:special_enrollment_period, :expired, family: family)
    end

    it "should have the SEP instance" do
      expect(family.special_enrollment_periods.size).to eq 1
    end

    it "should return a SEP class" do
      expect(family.special_enrollment_periods.first).to be_a SpecialEnrollmentPeriod
    end

    it "should indicate no active SEPs" do
      expect(family.is_under_special_enrollment_period?).to be_falsey
    end

    it "current_special_enrollment_periods should return []" do
      expect(family.current_special_enrollment_periods).to eq []
    end

    it "should set person hbx id to nil" do
      subject.migrate
      person.reload
      expect(family.special_enrollment_periods.map(&:valid?)).to eq [true]
    end
  end
end