require 'rails_helper'

module BenefitSponsors
  RSpec.describe Organizations::OrganizationForms::BrokerManagementForm, type: :model, dbclean: :after_each do

    subject { BenefitSponsors::Organizations::OrganizationForms::BrokerManagementForm }

    let!(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_cca_employer_profile)}
    let(:employer_profile) { organization.employer_profile }
    let!(:broker_agency_profile) { FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: 'shop', legal_name: 'Legal Name1') }
    let!(:broker_role) { FactoryGirl.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }

    describe "#for_create" do

      let(:params) {
        {:broker_agency_profile_id=> broker_agency_profile.id.to_s,
         :broker_role_id=> broker_role.id.to_s,
         :employer_profile_id=> employer_profile.id.to_s}
      }

      let(:create_form) { subject.for_create params }

      it 'instantiates a new Broker Management Form' do
        expect(create_form).to be_an_instance_of(subject)
      end

      it "instantiates service" do
        expect(create_form.send(:service)).to be_instance_of(BenefitSponsors::Services::BrokerManagementService)
      end

      it "should assign the create params to broker management forms" do
        expect(create_form.employer_profile_id).to eq params[:employer_profile_id]
        expect(create_form.broker_agency_profile_id).to eq params[:broker_agency_profile_id]
        expect(create_form.broker_role_id).to eq params[:broker_role_id]
        expect(create_form.direct_terminate).to eq nil
        expect(create_form.termination_date).to eq nil
      end

      it "create_form should be valid" do
        create_form.validate
        expect(create_form).to be_valid
      end

      it 'creates a new broker_agency_accounts in benefit_sponsorship when saved' do
        create_form.save
        employer_profile.active_benefit_sponsorship.reload
        expect(employer_profile.active_benefit_sponsorship.broker_agency_accounts.count).to eq 1
      end

    end

    describe "#terminate" do
      let!(:benefit_sponsorship_with_account) {FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_broker_agency_account, profile: employer_profile)}
      let!(:broker_agency_account) {benefit_sponsorship_with_account.broker_agency_accounts.first}
      let!(:broker_agency_profile) {broker_agency_account.broker_agency_profile}
      let!(:writing_agent) {broker_agency_account.writing_agent}


      let(:terminate_params) {
        {:direct_terminate=>'true',
         :termination_date=>TimeKeeper.date_of_record.strftime("%m/%d/%Y"),
         :broker_agency_profile_id=> broker_agency_profile.id.to_s,
         :broker_role_id=> writing_agent.id.to_s,
         :employer_profile_id=> employer_profile.id.to_s}
      }

      let!(:termiante_form) { subject.for_terminate terminate_params }


      before do
        organization.benefit_sponsorships =[benefit_sponsorship_with_account]
        organization.save
      end

      it "should assign the termiante params to broker management forms" do
        expect(termiante_form.employer_profile_id).to eq termiante_form[:employer_profile_id]
        expect(termiante_form.broker_agency_profile_id).to eq termiante_form[:broker_agency_profile_id]
        expect(termiante_form.broker_role_id).to eq termiante_form[:broker_role_id]
        expect(termiante_form.direct_terminate).to eq true
        expect(termiante_form.termination_date).to eq TimeKeeper.date_of_record
      end

      it "create_form should be valid" do
        termiante_form.validate
        expect(termiante_form).to be_valid
      end

      it 'should terminate broker_agency_account in benefit_sponsorship when terminated' do
        expect(employer_profile.active_benefit_sponsorship.broker_agency_accounts.count).to eq 1
        termiante_form.terminate
        employer_profile.active_benefit_sponsorship.reload
        expect(employer_profile.active_benefit_sponsorship.broker_agency_accounts.count).to eq 0
      end
    end
  end
end