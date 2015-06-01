require 'rails_helper'

describe ::Forms::PlanYearForm, "when newly created" do
  subject { ::Forms::PlanYearForm.new(PlanYear.new) }

  before :each do
    subject.valid?
  end

  [:start_on, :end_on, :open_enrollment_start_on, :open_enrollment_end_on].each do |attr|
    it "should have errors on #{attr}" do
      expect(subject).to have_errors_on(attr.to_sym)
    end
  end
end
