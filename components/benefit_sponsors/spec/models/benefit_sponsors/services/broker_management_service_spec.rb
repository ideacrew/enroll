require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::BrokerManagementService, type: :model, :dbclean => :after_each do

    subject { BenefitSponsors::Services::BrokerManagementService.new }

    let!(:employer_profile) { FactoryGirl.create(:benefit_sponsors_organizations_aca_shop_dc_employer_profile) }
    let!(:broker_agency_profile1) { FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: 'both', legal_name: 'Legal Name1') }
    let!(:person1) { FactoryGirl.create(:person) }
    let!(:broker_role1) { FactoryGirl.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id, person: person1) }
    let!(:benefit_sponsorship) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, :with_benefit_market, organization: employer_profile.organization, profile_id: employer_profile.id) }
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

    describe 'for assign_agencies' do
      before :each do
        subject.assign_agencies(broker_management_form_create)
      end

      it 'should return true once it succesfully assigns broker agency to the employer_profile' do
        expect(subject.assign_agencies(broker_management_form_create)).to be_truthy
      end

      it 'should succesfully assigns broker agency to the employer_profile' do
        expect(employer_profile.active_benefit_sponsorship.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id).to eq broker_agency_profile1.id
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
        expect(employer_profile.active_benefit_sponsorship.broker_agency_accounts).not_to eq []
        subject.terminate_agencies(broker_management_form_terminate)
        expect(employer_profile.active_benefit_sponsorship.broker_agency_accounts).to eq []
      end
    end
  end
end