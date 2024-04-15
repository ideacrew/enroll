# frozen_string_literal: true

require "rails_helper"

RSpec.describe Insured::ConsumerRolesController do
  describe "PUT update, for an IVL market person with a consumer role" do
    let(:person_id) { "SOME PERSON ID" }
    let(:consumer_role_id) { "SOME CONSUMER ROLE ID" }
    let(:user) do
      instance_double(
        User,
        person: person,
        has_hbx_staff_role?: false
      )
    end
    let(:family) { instance_double(Family, id: family_id) }
    let(:family_id) { "SOME FAMILY ID" }
    let(:family_member) do
      instance_double(
        FamilyMember,
        person: dependent_person,
        family: family
      )
    end
    let(:person) do
      instance_double(
        Person,
        is_resident_role_active?: false,
        no_dc_address: false,
        has_multiple_roles?: false,
        id: person_id,
        agent?: false,
        first_name: "John",
        last_name: "Smith",
        ssn: "123",
        dob: TimeKeeper.date_of_record - 30.years
      )
    end
    let(:consumer_role) do
      double(
        person: person,
        policy_class: ConsumerRolePolicy
      )
    end

    let(:person_controller_parameters) do
      ActionController::Parameters.new(person_update_properties).permit!
    end

    before(:each) do
      sign_in(user)
      allow(ConsumerRole).to receive(:find).with(consumer_role_id).and_return(consumer_role)
      allow(consumer_role).to receive(:skip_consumer_role_callbacks=).and_return(true)
      allow(consumer_role).to receive(:update_by_person).with({"skip_person_updated_event_callback" => true, "skip_lawful_presence_determination_callbacks" => true}.merge(person_controller_parameters)).and_return(true)
      allow(EnrollRegistry[:mec_check].feature).to receive(:is_enabled).and_return(false)
      allow(EnrollRegistry[:shop_coverage_check].feature).to receive(:is_enabled).and_return(false)
      allow(person).to receive(:mec_check_eligible?).and_return(false)
    end

    describe "when the value for 'is_applying_coverage' is provided" do
      let(:is_applying_coverage_value) { "false" }
      let(:person_update_properties) do
        {
          "first_name" => "Person First Name",
          "is_applying_coverage" => is_applying_coverage_value
        }
      end

      it "updates the 'is_applying_coverage' value for the dependent" do
        expect(consumer_role).to receive(:update_attribute).with(:is_applying_coverage, is_applying_coverage_value).and_return(true)
        put :update, params: {id: consumer_role_id, person: person_update_properties, exit_after_method: true}
      end
    end

    describe "when the value for 'is_applying_coverage' is NOT provided" do
      let(:person_update_properties) do
        { "first_name" => "Person First Name" }
      end

      it "does not change the 'is_applying_coverage' value for the dependent" do
        expect(consumer_role).not_to receive(:update_attribute)
        put :update, params: {id: consumer_role_id, person: person_update_properties, exit_after_method: true}
      end
    end
  end

  describe "help_paying_coverage" do

    context 'when FAA feature enabled' do
      let(:user) { FactoryBot.create :user, :with_consumer_role }

      before do
        allow(EnrollRegistry[:aca_individual_market].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:financial_assistance].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:validate_quadrant].feature).to receive(:is_enabled).and_return(true)
        # allow(EnrollRegistry).to receive(:feature_enabled?).with(:location_residency_verification_type).and_return(true)
        allow(controller).to receive(:authorize).and_return(true)
        sign_in user
      end

      subject { get :help_paying_coverage }

      it 'renders help_paying_coverage template' do
        expect(subject).to render_template('insured/consumer_roles/help_paying_coverage')
      end
    end

    context 'when FAA feature disabled' do
      let(:user) { FactoryBot.create :user, :with_consumer_role }

      before do
        allow(EnrollRegistry[:aca_individual_market].feature).to receive(:is_enabled).and_return(true)
        allow(EnrollRegistry[:financial_assistance].feature).to receive(:is_enabled).and_return(false)
        allow(EnrollRegistry[:validate_quadrant].feature).to receive(:is_enabled).and_return(true)
        # allow(EnrollRegistry).to receive(:feature_enabled?).with(:location_residency_verification_type).and_return(true)
        sign_in user
      end

      subject { get :help_paying_coverage }

      it 'renders help_paying_coverage template' do
        expect(subject.status).to eq(404)
        expect(response.body).to include("The page you were looking for doesn't exist (404)")
      end
    end
  end

  describe "help_paying_for_coverage_response" do
    let(:user) { FactoryBot.create :user, :with_consumer_role }
    before { sign_in user }

    subject { get :help_paying_coverage_response, params: params }

    context "is_applying_for_assistance false" do
      let(:params) { { is_applying_for_assistance: false } }

      it 'redirects to insured_family_members_path' do
        expect(subject).to redirect_to(insured_family_members_path(consumer_role_id: user.person.consumer_role.id))
      end
    end

    context "is_applying_for_assistance true" do
      let(:current_hbx_profile) { OpenStruct.new(under_open_enrollment?: true) }
      let(:params) { { is_applying_for_assistance: true } }
      let(:result) { ::Dry::Monads::Result::Success.new(1) }

      context "iap year selection is enabled and IVL oe end date is in future" do
        before do
          allow(HbxProfile).to receive(:current_hbx).and_return(current_hbx_profile)
          allow(EnrollRegistry[:iap_year_selection].feature).to receive(:is_enabled).and_return(true)
          allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, 1, 1))
        end

        it "redirects to financial assistance's year selection page" do
          expect(Operations::FinancialAssistance::Apply).to receive(:new) do
            double(call: result)
          end

          expect(subject).to redirect_to('/financial_assistance/applications/1/application_year_selection')
        end
      end

      context "iap year selection is disabled and IVL oe end date is in future" do
        before do
          allow(EnrollRegistry[:iap_year_selection].feature).to receive(:is_enabled).and_return(false)
          allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(TimeKeeper.date_of_record.year, 1, 1))
        end

        it "redirects to financial assistance's year selection page" do
          expect(Operations::FinancialAssistance::Apply).to receive(:new) do
            double(call: result)
          end

          expect(subject).to redirect_to('/financial_assistance/applications/1/application_checklist')
        end
      end
    end
  end
end
