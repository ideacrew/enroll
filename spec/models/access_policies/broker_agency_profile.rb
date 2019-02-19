require 'rails_helper'

describe AccessPolicies::BrokerAgencyProfile, :dbclean => :after_each do
  subject { AccessPolicies::BrokerAgencyProfile.new(user) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:broker_controller) { BrokerAgencies::ProfilesController.new }
  let(:controller) { BrokerAgencies::BrokerAgencyStaffRolesController.new }
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }


  context 'authorize edit' do
    context 'for an admin user' do
      let(:person) {FactoryGirl.create(:person, :with_hbx_staff_role) }

      it 'should authorize' do
        expect(subject.authorize_edit(broker_agency_profile, controller)).to be_truthy
      end
    end

    context 'for an broker staff user of broker agency profile' do
      let(:person) { FactoryGirl.create(:person) }
      let(:broker_agency_staff_role) {FactoryGirl.build(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id)}

      before do
        person.broker_agency_staff_roles << broker_agency_staff_role
      end

      it 'should authorize' do
        broker_agency_profile = BrokerAgencyProfile.find(person.broker_agency_staff_roles.first.broker_agency_profile.id.to_s)
        expect(subject.authorize_edit(broker_agency_profile, controller)).to be_truthy
      end
    end

    context 'has broker staff role of broker agency profile' do
      let(:user) { FactoryGirl.create(:user, person: person) }
      let(:person) { FactoryGirl.create(:person) }
      let(:broker_agency_staff_role) {FactoryGirl.build(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id)}
      let(:staff_role) { person.broker_agency_staff_roles << broker_agency_staff_role }
      let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }

      before do
        person.broker_agency_staff_roles << broker_agency_staff_role
      end

      it 'should authorize' do
        broker_agency_profile = BrokerAgencyProfile.find(person.broker_agency_staff_roles.first.broker_agency_profile.id.to_s)
        allow(person).to receive(:has_hbx_staff_role?).and_return true
        expect(subject.authorize_edit(broker_agency_profile, controller)).to be_truthy
      end
    end

    context 'is staff of broker agency' do
      let(:person) { FactoryGirl.create(:person) }

      it 'should authorize' do
        allow(Person).to receive(:staff_for_broker).and_return([person])
        expect(subject.authorize_edit(broker_agency_profile, controller)).to be_truthy
      end
    end

    context 'has no broker staff or hbx role to broker agency' do
      let(:person) { FactoryGirl.create(:person) }

      it 'should redirect you to new' do
        expect(controller).to receive(:redirect_to_new)
        subject.authorize_edit(broker_agency_profile, controller)
      end
    end
  end
end
