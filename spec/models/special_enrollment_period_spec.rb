require 'rails_helper'

RSpec.describe SpecialEnrollmentPeriod, :type => :model do

  let(:event_date) { Date.today }
  let(:expired_event_date) { Date.today - 1.year }
  let(:first_of_following_month) { Date.today.end_of_month + 1 }
  let(:qle_effective_date) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date) }
  let(:qle_first_of_month) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_first_of_month) }

  describe "it should set SHOP Special Enrollment Period dates based on QLE kind" do
    let(:sep_effective_date) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_effective_date, qle_on: event_date) }
    let(:sep_first_of_month) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_first_of_month, qle_on: event_date) }
    let(:sep_expired) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_first_of_month, qle_on: expired_event_date) }

    context "SHOP QLE and event date are specified" do

      it "should set begin_on date to date of event" do
        expect(sep_effective_date.begin_on).to eq event_date
      end

      context "and qle is effective on date of event" do
        it "should set effective date to date of event" do
          expect(sep_effective_date.effective_on).to eq event_date
        end
      end

      context "and QLE is effective on first of following month" do
        it "should set effective date to date of event" do
          expect(sep_first_of_month.effective_on).to eq first_of_following_month
        end
      end
    end

    context "SEP is active as of this date" do
      it "#is_active? should return true" do
        expect(sep_first_of_month.is_active?).to be_truthy
      end
    end

    context "SEP occured in the past, and is no longer active" do

      it "#is_active? should return false" do
        expect(sep_expired.is_active?).to be_falsey
      end
    end
  end
end
