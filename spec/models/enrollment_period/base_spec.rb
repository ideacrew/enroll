require 'rails_helper'

RSpec.describe EnrollmentPeriod::Base, :type => :model do
  let(:title)     { "Spec special enrollment period" }
  let(:start_on)  { Date.current }
  let(:end_on)    { Date.current + 30.days }

  let(:valid_params){
    {
      title: title,
      start_on: start_on,
      end_on: end_on,
    }
  }

  context "when initialized" do
    context "with no start_on" do
      let(:params) {valid_params.except(:start_on)}

      it "should be invalid" do
        expect(EnrollmentPeriod::Base.create(**params).errors[:start_on].any?).to be_truthy
      end
    end

    context "with no end_on" do
      let(:params) {valid_params.except(:end_on)}

      it "should be invalid" do
        expect(EnrollmentPeriod::Base.create(**params).errors[:end_on].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:base_enrollment_period) { EnrollmentPeriod::Base.new(**params) }

      it "should be valid" do
        expect(base_enrollment_period.valid?).to be_truthy
      end
    end
  end

end
