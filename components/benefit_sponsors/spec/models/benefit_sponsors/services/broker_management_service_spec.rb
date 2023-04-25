require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::BrokerManagementService, type: :model, :dbclean => :after_each do
    include ::L10nHelper

    subject { BenefitSponsors::Services::BrokerManagementService.new }

    let!(:rating_area)                  { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)                 { FactoryBot.create_default :benefit_markets_locations_service_area }
    let(:site)                          { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, EnrollRegistry[:enroll_app].setting(:site_key).item.to_sym) }
    let(:organization)                  { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)              { organization.employer_profile }
    let(:active_benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

    let!(:broker_organization)    { FactoryBot.build(:benefit_sponsors_organizations_general_organization, site: site)}
    let!(:broker_agency_profile1) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, organization: broker_organization, legal_name: 'Legal Name1') }
    let!(:person1) { FactoryBot.create(:person) }
    let!(:broker_role1) { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id, person: person1) }
    let(:broker_management_form_create) { BenefitSponsors::Organizations::OrganizationForms::BrokerManagementForm.new(
                                          employer_profile_id: employer_profile.id,
                                          broker_agency_profile_id: broker_agency_profile1.id,
                                          broker_role_id: broker_role1.id)
                                        }

    let(:broker_management_form_terminate) { BenefitSponsors::Organizations::OrganizationForms::BrokerManagementForm.new(
                                              employer_profile_id: employer_profile.id,
                                              broker_agency_profile_id: broker_agency_profile1.id,
                                              direct_terminate: 'true',
                                              termination_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'))
                                            }
    let(:general_agency_profile) do
      FactoryBot.create(
        :benefit_sponsors_organizations_general_organization,
        :with_site,
        :with_general_agency_profile
      ).profiles.first
    end

    before :each do
      active_benefit_sponsorship.save!
      broker_agency_profile1.update_attributes!(primary_broker_role_id: broker_role1.id)
      broker_agency_profile1.approve!
      organization.reload
    end

    describe 'for assign_agencies' do
      before :each do
        broker_agency_profile1.update_attributes!(default_general_agency_profile_id: general_agency_profile.id)
        subject.assign_agencies(broker_management_form_create)
      end

      it 'should return true once it succesfully assigns broker agency to the employer_profile' do
        expect(subject.assign_agencies(broker_management_form_create)).to be_truthy
      end

      it 'should send a message to the general_agency' do
        general_agency_profile.reload
        subject = l10n("employers.broker_agency_notice.subject", broker_legal_name: broker_agency_profile1.organization.legal_name, agency_legal_name: general_agency_profile.legal_name)
        body = l10n("employers.broker_agency_notice.body", agency_legal_name: general_agency_profile.legal_name, employer_legal_name: employer_profile.legal_name)
        expect(general_agency_profile.inbox.messages.map(&:body)).to include(body)
        expect(general_agency_profile.inbox.messages.map(&:subject)).to include(subject)
      end

      it 'should send a message to the employer' do
        employer_profile.reload
        subject = l10n("employers.broker_agency_notice.subject", broker_legal_name: broker_agency_profile1.organization.legal_name, agency_legal_name: general_agency_profile.legal_name)
        body = l10n("employers.broker_agency_notice.body", agency_legal_name: general_agency_profile.legal_name, employer_legal_name: employer_profile.legal_name)
        expect(employer_profile.inbox.messages.map(&:body)).to include(body)
        expect(employer_profile.inbox.messages.map(&:subject)).to include(subject)
      end

      it 'should succesfully assigns broker agency to the employer_profile' do
        active_benefit_sponsorship.reload
        expect(active_benefit_sponsorship.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id).to eq broker_agency_profile1.id
      end

      it 'should send a message to the broker' do
        person1.reload
        expect(person1.inbox.messages.map(&:body)).to include("You have been selected as a broker by #{employer_profile.legal_name}")
        expect(person1.inbox.messages.map(&:subject)).to include("You have been select as the Broker")
      end
    end

    describe 'for terminate_agencies' do
      before :each do
        subject.assign_agencies(broker_management_form_create)
      end

      it 'should return true once it succesfully assigns broker agency to the employer_profile' do
        expect(subject.terminate_agencies(broker_management_form_terminate)).to be_truthy
      end

      it 'should succesfully assigns broker agency to the employer_profile' do
        active_benefit_sponsorship.reload
        expect(active_benefit_sponsorship.broker_agency_accounts).not_to eq []
        subject.terminate_agencies(broker_management_form_terminate)
        active_benefit_sponsorship.reload
        expect(active_benefit_sponsorship.broker_agency_accounts).to eq []
      end
    end
  end
end
