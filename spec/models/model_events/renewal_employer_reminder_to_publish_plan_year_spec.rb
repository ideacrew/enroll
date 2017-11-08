require 'rails_helper'

describe 'ModelEvents::RenewalEmployerReminderToPublishPlanYearNotification' do

  let(:model_event) { "renewal_plan_year_publish_dead_line" }
  let(:notice_event) { "renewal_plan_year_publish_dead_line" }
  let(:start_on) { (TimeKeeper.date_of_record + 3.months).beginning_of_month }

  let!(:employer) { create(:employer_with_planyear, start_on: (TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year, plan_year_state: 'active') }
  let!(:model_instance) { build(:renewing_plan_year, employer_profile: employer, start_on: start_on, aasm_state: 'renewing_draft', benefit_groups: [benefit_group]) }
  let!(:benefit_group) { FactoryGirl.create(:benefit_group) }
  let!(:date_mock_object) { double("Date", day: 13)}
  describe "ModelEvent" do
    context "when renewal employer 2 days prior to publish due date" do

      it "should trigger model event" do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:plan_year_update) do |model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :renewal_plan_year_publish_dead_line, :klass_instance => model_instance, :options => {})
          end
        end

        ModelEvents::PlanYear.date_change_event(date_mock_object)
      end
    end
  end
end
