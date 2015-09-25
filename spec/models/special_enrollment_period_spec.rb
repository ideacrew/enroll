require 'rails_helper'

RSpec.describe SpecialEnrollmentPeriod, :type => :model do

  let(:event_date) { Date.today }
  let(:expired_event_date) { Date.today - 1.year }
  let(:first_of_following_month) { Date.today.end_of_month + 1 }
  let(:qle_effective_date) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date) }
  let(:qle_first_of_month) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_first_of_month) }

  describe "it should set SHOP Special Enrollment Period dates based on QLE kind" do
    let(:sep_effective_date) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_effective_date, effective_on_kind: 'date_of_event', qle_on: event_date) }
    let(:sep_first_of_month) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_first_of_month, effective_on_kind: 'first_of_month', qle_on: event_date) }
    let(:sep_expired) { SpecialEnrollmentPeriod.new(qualifying_life_event_kind: qle_first_of_month, qle_on: expired_event_date) }
    let(:sep) { SpecialEnrollmentPeriod.new }
    let(:qle) { FactoryGirl.create(:qualifying_life_event_kind) }

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

      context "and qle is first_of_next_month" do
        it "when is_dependent_loss_of_coverage" do
          sep.effective_on_kind = "first_of_next_month"
          sep.qualifying_life_event_kind = qle
          allow(qle).to receive(:is_dependent_loss_of_coverage?).and_return true
          allow(qle).to receive(:employee_gaining_medicare).and_return (TimeKeeper.date_of_record - 1.day)
          sep.qle_on = TimeKeeper.date_of_record + 40.days
          expect(sep.effective_on).to eq (TimeKeeper.date_of_record - 1.day)
        end

        context "when is_moved_to_dc" do
          it "when current_date > qle on" do
            sep.effective_on_kind = "first_of_next_month"
            sep.qualifying_life_event_kind = qle
            allow(qle).to receive(:is_moved_to_dc?).and_return true
            sep.qle_on = TimeKeeper.date_of_record - 40.days
            expect(sep.effective_on).to eq (TimeKeeper.date_of_record.end_of_month + 1.day)
          end

          context "when current_date < qle on" do
            it "qle on is not beginning_of_month" do
              sep.effective_on_kind = "first_of_next_month"
              sep.qualifying_life_event_kind = qle
              allow(qle).to receive(:is_moved_to_dc?).and_return true
              sep.qle_on = TimeKeeper.date_of_record.end_of_month + 2.days
              expect(sep.effective_on).to eq ((TimeKeeper.date_of_record.end_of_month+2.days).end_of_month + 1.day)
            end

            it "qle on is beginning_of_month" do
              sep.effective_on_kind = "first_of_next_month"
              sep.qualifying_life_event_kind = qle
              allow(qle).to receive(:is_moved_to_dc?).and_return true
              sep.qle_on = TimeKeeper.date_of_record.end_of_month + 1.days
              expect(sep.effective_on).to eq (TimeKeeper.date_of_record.end_of_month+1.days)
            end
          end
        end

        it "should set effective date to date of event" do
          sep.qualifying_life_event_kind = qle
          sep.effective_on_kind = "first_of_next_month"
          sep.qle_on = TimeKeeper.date_of_record + 40.days
          expect(sep.effective_on).to eq (TimeKeeper.date_of_record.end_of_month + 1.day)
        end
      end

      it "and qle is fixed_first_of_next_month" do
        sep.qualifying_life_event_kind = qle
        sep.effective_on_kind = "fixed_first_of_next_month"
        sep.qle_on = event_date
        expect(sep.effective_on).to eq first_of_following_month
      end

      it "and qle is exact_date" do
        sep.qualifying_life_event_kind = qle
        sep.effective_on_kind = "exact_date"
        sep.qle_on = event_date
        expect(sep.effective_on).to eq event_date
      end

      context "for first_of_month" do
        before :each do
          sep.qualifying_life_event_kind = qle
          sep.effective_on_kind = "first_of_month"
        end

        it "should the first of month" do
          sep.qle_on = event_date
          expect(sep.effective_on).to eq [event_date, TimeKeeper.date_of_record].max.end_of_month + 1.day
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
