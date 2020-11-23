require "rails_helper"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe Forms::BulkActionsForAdmin, ".cancel_enrollments" do

  let(:params) { {
    :family_actions_id => "family_actions_5824903a7af880f17a000009",
    :family_id => "5824903a7af880f17a000009",
    :commit => "Submit",
    :controller => "exchanges/hbx_profiles",
    :action => "update_cancel_enrollment"}
  }

  subject {
    Forms::BulkActionsForAdmin.new(params)
  }

  context 'initialize new form model with the params from the controller' do

    it "should store the value of params[:family_id] in the @family_id variable" do
      expect(subject.family_id).to eq(params[:family_id])
    end

    it "should store the value of params[:family_actions_id] in the @row variable" do
      expect(subject.row).to eq(params[:family_actions_id])
    end

    it "should store the value of params[:result] in the @row variable" do
      expect(subject.row).to eq(params[:family_actions_id])
    end

  end

  describe 'aasm_state#handle_edi_transmissions', dbclean: :after_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"

    let(:benefit_package)  { initial_application.benefit_packages.first }
    let(:benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_package)}
    let(:employee_role) { FactoryGirl.create(:benefit_sponsors_employee_role, person: person, employer_profile: benefit_sponsorship.profile, census_employee_id: census_employee.id, benefit_sponsors_employer_profile_id: abc_profile.id) }
    let(:census_employee) do
      FactoryGirl.create(:census_employee,
                         employer_profile: benefit_sponsorship.profile,
                         benefit_sponsorship: benefit_sponsorship,
                         benefit_group_assignments: [benefit_group_assignment])
    end
    let(:person)       { FactoryGirl.create(:person, :with_family) }
    let!(:family)       { person.primary_family }
    let!(:hbx_enrollment) do
      hbx_enrollment = FactoryGirl.create(:hbx_enrollment,
                                          :with_enrollment_members,
                                          :with_product,
                                          household: family.active_household,
                                          aasm_state: "coverage_selected",
                                          effective_on: initial_application.start_on,
                                          rating_area_id: initial_application.recorded_rating_area_id,
                                          sponsored_benefit_id: initial_application.benefit_packages.first.health_sponsored_benefit.id,
                                          sponsored_benefit_package_id: initial_application.benefit_packages.first.id,
                                          benefit_sponsorship_id: initial_application.benefit_sponsorship.id,
                                          employee_role_id: employee_role.id)
      hbx_enrollment.benefit_sponsorship = benefit_sponsorship
      hbx_enrollment.save!
      hbx_enrollment
    end

    context "cancelling enrollment before close of quiet period" do
      let(:current_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }

      let(:cancel_arguments) do
        [
          {"cancel_date" => current_effective_date,
           "cancel_hbx_" => hbx_enrollment.id,
           "transmit_hbx_" => hbx_enrollment.hbx_id,
           "family_actions_id" => family.id,
           "family_id" => family.id}
        ]
      end

      let(:subject) { Forms::BulkActionsForAdmin.new(*cancel_arguments)}
      let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

      it "should cancel enrollment and not trigger cancel event" do
        expect(subject).not_to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => hbx_enrollment.hbx_id,
                                                                                                     "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                                                                     "is_trading_partner_publishable" => false})
        subject.cancel_enrollments
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
      end

      context "not a shop enrollment" do
        before do
          hbx_enrollment.update_attributes(kind: "individual", sponsored_benefit_package_id: nil)
        end

        it "should cancel enrollment and trigger cancel event" do
          expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => hbx_enrollment.hbx_id,
                                                                                                   "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                                                                   "is_trading_partner_publishable" => false})
          subject.cancel_enrollments
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
        end
      end
    end

    context "cancelling enrollment after quiet period ended" do
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:cancel_arguments) do
        [
          {"cancel_date" => current_effective_date,
           "cancel_hbx_" => hbx_enrollment.id,
           "transmit_hbx_" => hbx_enrollment.hbx_id,
           "family_actions_id" => family.id,
           "family_id" => family.id}
        ]
      end
      let(:subject) { Forms::BulkActionsForAdmin.new(*cancel_arguments)}
      let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

      it "should cancel enrollment and trigger cancel event" do
        expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to => glue_event_queue_name,
                                                                                                 "hbx_enrollment_id" => hbx_enrollment.hbx_id,
                                                                                                 "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                                                                 "is_trading_partner_publishable" => false})
        subject.cancel_enrollments
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
      end

      context "not a shop enrollment" do
        before do
          hbx_enrollment.update_attributes(kind: "individual", sponsored_benefit_package_id: nil)
        end

        it "should cancel enrollment and trigger cancel event" do
          expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => hbx_enrollment.hbx_id,
                                                                                                   "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                                                                   "is_trading_partner_publishable" => false})
          subject.cancel_enrollments
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_canceled"
        end
      end
    end

    context "terminating enrollment before close of quiet period" do
      let(:current_effective_date) { TimeKeeper.date_of_record.next_month.beginning_of_month }
      let(:term_arguments) do
        [
          {"termination_date_#{hbx_enrollment.id}" => current_effective_date.end_of_month.to_s,
           "terminate_hbx_" => hbx_enrollment.id,
           "transmit_hbx_" => hbx_enrollment.hbx_id,
           "family_actions_id" => family.id,
           "family_id" => family.id}
        ]
      end
      let(:subject) { Forms::BulkActionsForAdmin.new(*term_arguments)}
      let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

      it "should terminate enrollment and not trigger terminate event" do
        expect(subject).not_to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => hbx_enrollment.hbx_id,
                                                                                                     "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                                                                     "is_trading_partner_publishable" => false})
        subject.terminate_enrollments
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
        expect(hbx_enrollment.terminated_on).to eq current_effective_date.end_of_month
      end

      context "not a shop enrollment" do
        before do
          hbx_enrollment.update_attributes(kind: "individual", sponsored_benefit_package_id: nil)
        end

        it "should terminate enrollment and trigger terminate event" do
          expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => hbx_enrollment.hbx_id,
                                                                                                   "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                                                                   "is_trading_partner_publishable" => false})
          subject.terminate_enrollments
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
          expect(hbx_enrollment.terminated_on).to eq current_effective_date.end_of_month
        end
      end
    end

    context "terminating enrollment after quiet period ended" do
      let(:current_effective_date) { TimeKeeper.date_of_record.beginning_of_month }
      let(:term_arguments) do
        [
          {"termination_date_#{hbx_enrollment.id}" => current_effective_date.end_of_month.to_s,
           "terminate_hbx_" => hbx_enrollment.id,
           "transmit_hbx_" => hbx_enrollment.hbx_id,
           "family_actions_id" => family.id,
           "family_id" => family.id}
        ]
      end
      let(:subject) { Forms::BulkActionsForAdmin.new(*term_arguments)}
      let!(:glue_event_queue_name) { "#{Rails.application.config.acapi.hbx_id}.#{Rails.application.config.acapi.environment_name}.q.glue.enrollment_event_batch_handler" }

      it "should terminate enrollment and trigger terminate event" do
        expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => hbx_enrollment.hbx_id,
                                                                                                 "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                                                                 "is_trading_partner_publishable" => false})
        subject.terminate_enrollments
        hbx_enrollment.reload
        expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
        expect(hbx_enrollment.terminated_on).to eq current_effective_date.end_of_month
      end

      context "not a shop enrollment" do
        before do
          hbx_enrollment.update_attributes(kind: "individual", sponsored_benefit_package_id: nil)
        end

        it "should terminate enrollment and trigger terminate event" do
          expect(subject).to receive(:notify).with("acapi.info.events.hbx_enrollment.terminated", {:reply_to => glue_event_queue_name, "hbx_enrollment_id" => hbx_enrollment.hbx_id,
                                                                                                   "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
                                                                                                   "is_trading_partner_publishable" => false})
          subject.terminate_enrollments
          hbx_enrollment.reload
          expect(hbx_enrollment.aasm_state).to eq "coverage_terminated"
          expect(hbx_enrollment.terminated_on).to eq current_effective_date.end_of_month
        end
      end
    end
  end
end
