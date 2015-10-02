require 'rails_helper'

RSpec.describe EnrollmentPeriod::SpecialEnrollment, :type => :model do

  let(:family)        { FactoryGirl.build(:family, :with_primary_family_member) }
  let(:shop_qle)      { QualifyingLifeEventKind.create(
                              title: "I've entered into a legal domestic partnership",
                              action_kind: "add_benefit",
                              reason: " ",
                              edi_code: "33-ENTERING DOMESTIC PARTNERSHIP", 
                              market_kind: "shop", 
                              effective_on_kinds: ["first_of_month"],
                              pre_event_sep_in_days: 0,
                              post_event_sep_in_days: 30, 
                              is_self_attested: true, 
                              ordinal_position: 20,
                              event_kind_label: 'Date of domestic partnership',
                              tool_tip: "Enroll or add a family member due to a new domestic partnership"
                            )
                          }
  let(:ivl_qle)       { QualifyingLifeEventKind.create(
                              title: "I've had a baby",
                              tool_tip: "Household adds a member due to birth",
                              action_kind: "add_member",
                              market_kind: "individual",
                              event_kind_label: "Date of birth",
                              reason: " ",
                              edi_code: "02-BIRTH", 
                              ordinal_position: 10,
                              effective_on_kinds: ["date_of_event", "fixed_first_of_next_month"],
                              pre_event_sep_in_days: 0,
                              post_event_sep_in_days: 60,
                              is_self_attested: true
                            )
                          }
  let(:qle_on)         { Date.current }
  let(:effective_on)   { qle_on.end_of_month + 1.day }

  let(:valid_params){
    {
      family: family,
      qualifying_life_event_kind: shop_qle,
      qle_on: qle_on,
      effective_on: effective_on,
    }
  }

  context "new instance" do
    context "with no family" do
      let(:params) {valid_params.except(:family)}

      it "should be invalid" do
        expect{EnrollmentPeriod::SpecialEnrollment.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no qualifying_life_event_kind" do
      let(:params) {valid_params.except(:qualifying_life_event_kind)}

      it "should be invalid" do
        expect(EnrollmentPeriod::SpecialEnrollment.create(**params).errors[:qualifying_life_event_kind_id].any?).to be_truthy
      end
    end

    context "with no qle_on" do
      let(:params) {valid_params.except(:qle_on)}

      it "should be invalid" do
        expect(EnrollmentPeriod::SpecialEnrollment.create(**params).errors[:qle_on].any?).to be_truthy
      end
    end

    context "with no effective_on" do
      let(:params) {valid_params.except(:effective_on)}

      it "should be invalid" do
        expect(EnrollmentPeriod::SpecialEnrollment.create(**params).errors[:effective_on].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:base_enrollment_period) { EnrollmentPeriod::SpecialEnrollment.new(**params) }

      it "should be valid" do
        expect(base_enrollment_period.valid?).to be_truthy
      end
    end

  end




  let(:event_date) { TimeKeeper.date_of_record }
  let(:expired_event_date) { TimeKeeper.date_of_record - 1.year }
  let(:first_of_following_month) { TimeKeeper.date_of_record.end_of_month + 1 }
  let(:qle_effective_date) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_event_date) }
  let(:qle_first_of_month) { FactoryGirl.create(:qualifying_life_event_kind, :effective_on_first_of_month) }

  describe "it should set SHOP Special Enrollment Period dates based on QLE kind" do
    let(:sep_effective_date) { EnrollmentPeriod::SpecialEnrollment.new(qualifying_life_event_kind: qle_effective_date, effective_on_kind: 'date_of_event', qle_on: event_date) }
    let(:sep_first_of_month) { EnrollmentPeriod::SpecialEnrollment.new(qualifying_life_event_kind: qle_first_of_month, effective_on_kind: 'first_of_month', qle_on: event_date) }
    let(:sep_expired) { EnrollmentPeriod::SpecialEnrollment.new(qualifying_life_event_kind: qle_first_of_month, qle_on: expired_event_date) }
    let(:sep) { EnrollmentPeriod::SpecialEnrollment.new }
    let(:qle) { FactoryGirl.create(:qualifying_life_event_kind) }

    context "SHOP QLE and event date are specified" do
      it "should set start_on date to date of event" do
        expect(sep_effective_date.start_on).to eq event_date
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
