require 'rails_helper'

module BenefitSponsors
  RSpec.describe ::BenefitSponsors::Services::UpdateBrokerAgencyService, type: :model, :dbclean => :after_each do
    let(:params) {
      {
          :legal_name => broker_agency_profile.legal_name
      }
    }
    let(:service_class) { BenefitSponsors::Services::UpdateBrokerAgencyService }
    let(:broker_agency_profile)  { FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile) }

    let!(:primary_person) { FactoryGirl.create(:person, :with_family)}
    let!(:broker_agency_account) { agency_account = FactoryGirl.build(:benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile)
                                   primary_person.primary_family.update_attributes(broker_agency_accounts: [agency_account])
                                   agency_account
    }

    describe "#new" do
      let(:service_obj) { service_class.new(params)}
      it "should instantiate" do
        expect(service_obj.legal_name).to eq broker_agency_profile.legal_name
        expect(service_obj.broker_agency).to eq broker_agency_profile
      end
    end

    describe "#update_broker_profile_id" do

      before :each do
        old_broker_agency_profile.update_attributes(primary_broker_role: person.broker_role)
        person.broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: old_broker_agency_profile.id)
      end

      let(:formed_params) { {
          hbx_id: person.hbx_id
      }}
      let(:person) { FactoryGirl.create(:person, :with_broker_role)}
      let!(:old_broker_agency_profile) { BenefitSponsors::Organizations::BrokerAgencyProfile.new }
      let!(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, benefit_sponsors_broker_agency_profile_id: old_broker_agency_profile.id, person: person) }

      it "should update profile_id" do
        service_obj = service_class.new(params)
        service_obj.update_broker_profile_id(formed_params)
        expect(person.broker_agency_staff_roles.first.benefit_sponsors_broker_agency_profile_id).to eq person.broker_role.benefit_sponsors_broker_agency_profile_id
      end
    end

    describe "#update_broker_agency_attributes" do
      let(:service_obj) { service_class.new(params)}

      it "should update corporate_npn"do
        service_obj.update_broker_agency_attributes({corporate_npn: "12234234"})
        broker_agency_profile.reload
        expect(broker_agency_profile.corporate_npn).to eq "12234234"
      end
    end

    describe "#update_organization_attributes" do
      let(:service_obj) { service_class.new(params)}

      it "should update organization fein" do
        service_obj.update_organization_attributes({fein: "097979787"})
        broker_agency_profile.organization.reload
        expect(broker_agency_profile.organization.fein).to eq "097979787"
      end
    end

    describe "#update_broker_assignment_date" do
      let(:service_obj) { service_class.new(params)}
      let!(:start_date) { DateTime.new(2018, 8, 29, 0, 0, 0).change(day: 1)  }
      let!(:formed_params) { {hbx_ids: [primary_person.hbx_id], start_date: start_date}}

      it "should update broker agnecy account start date" do
        service_obj.update_broker_assignment_date(formed_params)
        expect(broker_agency_account.reload.start_on).to eq start_date
      end
    end
  end
end
