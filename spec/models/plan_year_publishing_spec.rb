require "rails_helper"

describe PlanYear, "that is:
- finished open enrollment
- paid the binder
- is configured to wait for the 15th of the month
" do

  let(:employer_profile) { EmployerProfile.new(:aasm_state => "binder_paid") }

  before :each do
    allow(TimeKeeper).to receive(:date_of_record).and_return(current_date)
  end

  subject do
    PlanYear.new({
      :aasm_state => "enrolled",
      :open_enrollment_end_on => Date.new(2017, 6, 15),
      :start_on => Date.new(2017, 7, 1),
      :employer_profile => employer_profile
    })
  end

  describe "and has reached the 15th" do
    let(:current_date) { Date.new(2017, 6, 15) }

    it "is NOT eligible for export" do
      expect(subject.eligible_for_export?).to be_falsey
    end

  end

  describe "and has reached the 16th" do
    let(:current_date) { Date.new(2017, 6, 16) }

    it "is eligible for export" do
      expect(subject.eligible_for_export?).to be_truthy
    end

  end

  describe "late initial employer after monthly transmission i.e after 16th" do
    (17..30).each do |date|
      let(:current_date) { Date.new(2017, 6, date) }
      context "late initial employer on #{date} day of the month " do
        it "is eligible for export" do
          expect(subject.eligible_for_export?).to be_truthy
        end
      end
    end
  end

  describe "late initial employer on effective date of month" do
    let(:current_date) { Date.new(2017, 7, 1) }
    context "late initial employer on effective date of plan year " do
      it "is eligible for export" do
        subject.aasm_state = "active"
        expect(subject.eligible_for_export?).to be_truthy
      end
    end
  end
end

describe PlanYear, "that is:
- finished renewal open enrollment
- is configured to wait for the 15th of the month
- has reached the 16th
" do

  let(:employer_profile) { EmployerProfile.new(:aasm_state => "binder_paid") }

  before :each do
    allow(TimeKeeper).to receive(:date_of_record).and_return(current_date)
  end

  subject do
    PlanYear.new({
      :aasm_state => "renewing_enrolled",
      :open_enrollment_end_on => Date.new(2017, 6, 15),
      :start_on => Date.new(2017, 7, 1),
      :employer_profile => employer_profile
    })
  end

  describe "and has reached the 15th" do
    let(:current_date) { Date.new(2017, 6, 15) }

    it "is NOT eligible for export" do
      expect(subject.eligible_for_export?).to be_falsey
    end

  end

  describe "and has reached the 16th" do
    let(:current_date) { Date.new(2017, 6, 16) }

    it "is eligible for export" do
      expect(subject.eligible_for_export?).to be_truthy
    end

  end

  describe "late renewal employer after monthly transmission i.e after 16th" do
    (17..30).each do |date|
      let(:current_date) { Date.new(2017, 6, date) }
      context "late renewal employer on #{date} day of the month " do
        it "is eligible for export" do
          expect(subject.eligible_for_export?).to be_truthy
        end
      end
    end
  end

  describe "late renewal employer on effective date of month" do
    let(:current_date) { Date.new(2017, 7, 1) }
    context "late renewal employer on effective date of plan year " do
      it "is eligible for export" do
        subject.aasm_state = "active"
        expect(subject.eligible_for_export?).to be_truthy
      end
    end
  end
end
