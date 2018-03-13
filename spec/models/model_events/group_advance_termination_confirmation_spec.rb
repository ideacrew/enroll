require 'rails_helper'

describe 'ModelEvents::GroupAdvanceTerminationConfirmation', dbclean: :around_each  do
  let(:model_event)  { "group_advance_termination_confirmation" }
  let(:notice_event) { "group_advance_termination_confirmation" }
  let(:employer_profile){ create :employer_profile}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let(:person){ create :person}
  let(:benefit_group) { FactoryGirl.build(:benefit_group) }
  let!(:model_instance) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'active') }
  
  describe "ModelEvent" do
    context "when initial employer denial notice" do
      let(:prior_month_open_enrollment_start)  { TimeKeeper.date_of_record.beginning_of_month + Settings.aca.shop_market.open_enrollment.monthly_end_on - Settings.aca.shop_market.open_enrollment.minimum_length.days - 1.day}
      let(:valid_effective_date)   { (prior_month_open_enrollment_start - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).beginning_of_month }
      before do
        model_instance.effective_date = valid_effective_date
        model_instance.end_on = valid_effective_date + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day
        model_instance.benefit_groups = [benefit_group]
      end

      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :group_advance_termination_confirmation, :klass_instance => model_instance, :options => {})
          end
        end
        model_instance.terminate!
      end
    end
  end

  describe "NoticeTrigger" do
    context "when group advance request for termination" do
      subject { Observers::NoticeObserver.new }
      let(:model_event) { ModelEvents::ModelEvent.new(:group_advance_termination_confirmation, model_instance, {}) }

      it "should trigger notice event" do
        expect(subject).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.employer.group_advance_termination_confirmation"
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end

        subject.plan_year_update(model_event)
      end
    end
  end

end