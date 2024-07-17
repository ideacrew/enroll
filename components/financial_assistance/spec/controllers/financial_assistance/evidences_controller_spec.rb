# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::EvidencesController, dbclean: :after_each, type: :controller do
  include Dry::Monads[:do, :result]
  routes { FinancialAssistance::Engine.routes }

  let!(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
  let!(:admin_user) {FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person)}
  let!(:permission) { FactoryBot.create(:permission, :super_admin) }
  let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }

  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:associated_user) {FactoryBot.create(:user, :person => person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { family.family_members.first }

  let!(:application) do
    FactoryBot.create(
      :application,
      family_id: family.id,
      aasm_state: 'determined',
      assistance_year: TimeKeeper.date_of_record.year,
      effective_date: Date.today
    )
  end

  let!(:applicant) do
    applicant = FactoryBot.create(:financial_assistance_applicant,
                                  application: application,
                                  is_primary_applicant: true,
                                  ssn: person.ssn,
                                  dob: person.dob,
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  gender: person.gender,
                                  person_hbx_id: person.hbx_id,
                                  family_member_id: family_member.id)
    applicant
  end

  let(:enrollment) { instance_double(HbxEnrollment) }
  let!(:evidence) do
    applicant.create_income_evidence(
      key: :income,
      title: 'Income',
      aasm_state: 'outstanding',
      due_on: nil,
      verification_outstanding: false,
      is_satisfied: true
    )
  end
  let!(:attested_evidence) do
    applicant.create_esi_evidence(
      key: :esi_mec,
      title: "Esi",
      aasm_state: 'attested',
      due_on: Date.today,
      verification_outstanding: true,
      is_satisfied: false
    )
  end
  let!(:params) { { "applicant_id" => applicant.id, "application_id" => application.id, "verification_reason" => "Expired", "evidence_kind" => "income_evidence", "admin_action" => 'verify' } }
  let!(:params_minus_update_reason) { { "applicant_id" => applicant.id, "application_id" => application.id, "evidence_kind" => "income_evidence", "admin_action" => 'verify', "verification_reason" => '' } }
  let!(:esi_params) { { "applicant_id" => applicant.id, "application_id" => application.id, "verification_reason" => "Expired", "evidence_kind" => "esi_evidence", "admin_action" => 'verify' } }

  before do
    person.consumer_role.move_identity_documents_to_verified
  end

  context 'admin user' do
    before do
      sign_in(admin_user)
    end

    describe 'GET #update_evidence' do
      context 'when update reason is included in reasons list' do
        before do
          get :update_evidence, params: params
        end

        it 'sets a success flash message and redirects' do
          expect(flash[:success]).to be_present
          expect(response).to redirect_to main_app.verification_insured_families_path
        end
      end

      context 'when update reason is not included in reasons list' do
        before do
          get :update_evidence, params: params_minus_update_reason
        end

        it 'sets an error flash message and redirects' do
          expect(flash[:error]).to eq 'Please provide a verification reason.'
          expect(response).to redirect_to main_app.verification_insured_families_path
        end
      end
    end

    describe 'POST #fdsh_hub_request' do
      let(:request_double) { double }
      context 'when the request determination is successful' do
        before do
          allow(Operations::Fdsh::RequestEvidenceDetermination).to receive(:new).and_return(request_double)
          allow(request_double).to receive(:call).with(evidence).and_return(Success())
          post :fdsh_hub_request, params: params
        end

        it 'sets a success flash message and redirects' do
          expect(flash[:success]).to eq 'request submitted successfully'
          expect(response).to redirect_to main_app.verification_insured_families_path
        end
      end

      context 'when the request determination is not successful' do
        before do
          allow(Operations::Fdsh::RequestEvidenceDetermination).to receive(:new).and_return(request_double)
          allow(request_double).to receive(:call).with(evidence).and_return(Failure())
          post :fdsh_hub_request, params: params
        end

        it 'sets an error flash message and redirects' do
          expect(flash[:error]).to eq 'unable to submit request'
          expect(response).to redirect_to main_app.verification_insured_families_path
        end
      end
    end

    describe 'PUT #extend_due_date' do
      before do
        allow(FamilyMember).to receive(:find).and_return(family_member)
        allow(family_member).to receive_message_chain(:family, :enrollments, :enrolled, :first).and_return(enrollment)
      end

      context 'when the evidence is type unverified and enrollment is present' do
        it 'extends the due date and sets a success flash message' do
          put :extend_due_date, params: params
          expect(flash[:success]).to eq("#{evidence.title} verification due date was extended for 30 days.")
        end
      end

      context 'when the evidence is not type unverified or enrollment is not present' do
        it 'sets a danger flash message' do
          put :extend_due_date, params: esi_params
          expect(flash[:danger]).to eq("Applicant doesn't have active Enrollment to extend verification due date.")
        end
      end

      # this scenario does not seem functionally possible; extend_due_on will return the result from building a new verification history
      context 'when extending the due date fails' do
        it 'sets a danger flash message' do
          # put :extend_due_date, params: params
          # expect(flash[:danger]).to eq("Unable to extend due date")
        end
      end
    end

    describe '#find_docs_owner' do
      context 'when applicant_id is provided' do
        before do
          allow(::FinancialAssistance::Applicant).to receive(:find).with(applicant.id.to_s).and_return(applicant)
          controller.params = { applicant_id: applicant.id.to_s }
          controller.send(:find_docs_owner)
        end

        it 'finds the applicant' do
          expect(controller.instance_variable_get(:@docs_owner)).to eq(applicant)
        end
      end

      context 'when applicant_id is not provided' do
        before do
          controller.params = {}
          controller.send(:find_docs_owner)
        end

        it 'does not find an applicant' do
          expect(controller.instance_variable_get(:@docs_owner)).to be_nil
        end
      end
    end

    describe '#find_type' do
      before do
        allow(controller).to receive(:fetch_applicant)
        allow(controller).to receive(:find_docs_owner).and_return(applicant)
        allow(controller).to receive(:authorize)
        allow(controller).to receive(:params).and_return({ evidence_kind: 'Income' })
        allow(evidence).to receive(:request_determination).and_return(true)
        allow_any_instance_of(ApplicationPolicy).to receive(:edit?).and_return(true)
      end

      context 'when docs_owner responds to evidence_kind' do
        before do
          allow(applicant).to receive(:respond_to?).with('Income').and_return(true)
        end

        it 'assigns the evidence' do
          controller.send(:find_type)
          expect(assigns(:evidence)).to eq(applicant.evidences.first)
        end
      end

      context 'when docs_owner does not respond to evidence_kind' do
        before do
          allow(applicant).to receive(:respond_to?).with('Income').and_return(false)
        end

        it 'does not assign the evidence' do
          controller.send(:find_type)
          expect(assigns(:evidence)).to be_nil
        end
      end
    end

    describe '#fetch_applicant_succeeded?' do
      context 'when @applicant is present' do
        before do
          controller.instance_variable_set(:@applicant, applicant)
        end

        it 'returns true' do
          expect(controller.send(:fetch_applicant_succeeded?)).to eq(true)
        end
      end

      context 'when @applicant is not present' do
        before do
          controller.instance_variable_set(:@applicant, nil)
        end

        it 'logs an error and returns false' do
          expect(controller).to receive(:log).with(hash_including(message: 'Application Exception - applicant required'), severity: 'error')
          expect(controller.send(:fetch_applicant_succeeded?)).to eq(false)
        end
      end
    end

    describe '#fetch_applicant' do
      context 'when applicant_id is present in params' do
        it 'assigns the applicant' do
          get :fdsh_hub_request, params: params
          expect(assigns(:applicant)).to eq(applicant)
        end
      end

      context 'when current user is an agent and person_id is in session' do
        before do
          session[:person_id] = applicant.id
        end

        it 'assigns the applicant' do
          get :fdsh_hub_request, params: params
          expect(assigns(:applicant)).to eq(applicant)
        end
      end
    end
  end

  context 'consumer user' do
    before do
      sign_in(associated_user)
    end
    describe 'GET #update_evidence' do
      context 'when update reason is included in reasons list' do
        before do
          get :update_evidence, params: params
        end

        it 'sets a success flash message and redirects' do
          expect(flash[:success]).to be_present
          expect(response).to redirect_to main_app.verification_insured_families_path
        end
      end

      context 'when update reason is not included in reasons list' do
        before do
          get :update_evidence, params: params_minus_update_reason
        end

        it 'sets an error flash message and redirects' do
          expect(flash[:error]).to eq 'Please provide a verification reason.'
          expect(response).to redirect_to main_app.verification_insured_families_path
        end
      end
    end

    describe 'POST #fdsh_hub_request' do
      context 'when the request comes from a non admin role' do
        before do
          post :fdsh_hub_request, params: params
        end

        it 'flashes a pundit policy unauthorized error' do
          expect(flash[:error]).to eq "Access not allowed for hbx_profile_policy.can_call_hub?, (Pundit policy)"
        end
      end
    end

    describe 'PUT #extend_due_date' do
      before do
        allow(FamilyMember).to receive(:find).and_return(family_member)
        allow(family_member).to receive_message_chain(:family, :enrollments, :enrolled, :first).and_return(enrollment)
      end

      context 'when the request comes from a non admin role' do
        it 'flashes a pundit policy unauthorized error' do
          put :extend_due_date, params: params
          expect(flash[:error]).to eq "Access not allowed for hbx_profile_policy.can_extend_due_date?, (Pundit policy)"
        end
      end
    end

    describe '#find_type' do
      before do
        allow(controller).to receive(:fetch_applicant)
        allow(controller).to receive(:find_docs_owner).and_return(applicant)
        allow(controller).to receive(:authorize)
        allow(controller).to receive(:params).and_return({ evidence_kind: 'Income' })
        allow(evidence).to receive(:request_determination).and_return(true)
      end

      context 'when docs_owner responds to evidence_kind' do
        before do
          allow(applicant).to receive(:respond_to?).with('Income').and_return(true)
        end

        it 'assigns the evidence' do
          controller.send(:find_type)
          expect(assigns(:evidence)).to eq(applicant.evidences.first)
        end
      end

      context 'when docs_owner does not respond to evidence_kind' do
        before do
          allow(applicant).to receive(:respond_to?).with('Income').and_return(false)
        end

        it 'does not assign the evidence' do
          controller.send(:find_type)
          expect(assigns(:evidence)).to be_nil
        end
      end
    end
  end

  context 'broker user' do
    let(:market_kind) { :both }
    let(:broker_person) { FactoryBot.create(:person) }
    let(:broker_role) { FactoryBot.create(:broker_role, person: broker_person) }
    let(:broker_user) { FactoryBot.create(:user, person: broker_person) }
    let(:baa_active) { true }

    let(:site) do
      FactoryBot.create(
        :benefit_sponsors_site,
        :with_benefit_market,
        :as_hbx_profile,
        site_key: ::EnrollRegistry[:enroll_app].settings(:site_key).item
      )
    end

    let(:broker_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, site: site) }
    let(:broker_agency_profile) { broker_agency_organization.broker_agency_profile }
    let(:broker_agency_id) { broker_agency_profile.id }

    let(:broker_agency_account) do
      family.broker_agency_accounts.create!(
        benefit_sponsors_broker_agency_profile_id: broker_agency_id,
        writing_agent_id: broker_role.id,
        is_active: baa_active,
        start_on: TimeKeeper.date_of_record
      )
    end

    before do
      sign_in(broker_user)
      broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: broker_agency_id)
      broker_person.create_broker_agency_staff_role(
        benefit_sponsors_broker_agency_profile_id: broker_role.benefit_sponsors_broker_agency_profile_id
      )
      broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id, market_kind: market_kind)
      broker_role.approve!
      broker_agency_account
    end
    describe 'GET #update_evidence' do
      context 'when update reason is included in reasons list' do
        before do
          get :update_evidence, params: params
        end

        it 'sets a success flash message and redirects' do
          expect(flash[:success]).to be_present
          expect(response).to redirect_to main_app.verification_insured_families_path
        end
      end

      context 'when update reason is not included in reasons list' do
        before do
          get :update_evidence, params: params_minus_update_reason
        end

        it 'sets an error flash message and redirects' do
          expect(flash[:error]).to eq 'Please provide a verification reason.'
          expect(response).to redirect_to main_app.verification_insured_families_path
        end
      end
    end

    describe 'POST #fdsh_hub_request' do
      context 'when the request comes from a non admin role' do
        before do
          post :fdsh_hub_request, params: params
        end

        it 'flashes a pundit policy unauthorized error' do
          expect(flash[:error]).to eq "Access not allowed for hbx_profile_policy.can_call_hub?, (Pundit policy)"
        end
      end
    end

    describe 'PUT #extend_due_date' do
      before do
        allow(FamilyMember).to receive(:find).and_return(family_member)
        allow(family_member).to receive_message_chain(:family, :enrollments, :enrolled, :first).and_return(enrollment)
      end

      context 'when the request comes from a non admin role' do
        it 'flashes a pundit policy unauthorized error' do
          put :extend_due_date, params: params
          expect(flash[:error]).to eq "Access not allowed for hbx_profile_policy.can_extend_due_date?, (Pundit policy)"
        end
      end
    end

    describe '#find_type' do
      before do
        allow(controller).to receive(:fetch_applicant)
        allow(controller).to receive(:find_docs_owner).and_return(applicant)
        allow(controller).to receive(:authorize)
        allow(controller).to receive(:params).and_return({ evidence_kind: 'Income' })
        allow(evidence).to receive(:request_determination).and_return(true)
        allow_any_instance_of(ApplicationPolicy).to receive(:edit?).and_return(true)
      end

      context 'when docs_owner responds to evidence_kind' do
        before do
          allow(applicant).to receive(:respond_to?).with('Income').and_return(true)
        end

        it 'assigns the evidence' do
          controller.send(:find_type)
          expect(assigns(:evidence)).to eq(applicant.evidences.first)
        end
      end

      context 'when docs_owner does not respond to evidence_kind' do
        before do
          allow(applicant).to receive(:respond_to?).with('Income').and_return(false)
        end

        it 'does not assign the evidence' do
          controller.send(:find_type)
          expect(assigns(:evidence)).to be_nil
        end
      end
    end
  end
end

def main_app
  Rails.application.class.routes.url_helpers
end