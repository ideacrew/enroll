# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::People::MergeDuplicateBrokerRole,
               dbclean: :after_each do
  describe 'consumer and broker person records exists for the person' do
    let(:consumer_person) do
      per =
        FactoryBot.create(
          :person,
          :with_consumer_role,
          :with_ssn,
          first_name: 'Hasse',
          last_name: 'Timur',
          gender: 'male'
        )
      per.addresses = [
        FactoryBot.build(
          :address,
          :mailing_kind,
          address_1: '1 Awesome Street NE',
          address_2: '#1',
          state: 'DC'
        )
      ]
      per.addresses <<
        FactoryBot.build(
          :address,
          address_1: '2 Awesome Street NE',
          address_2: '#2',
          state: 'DC'
        )
      per.emails = [FactoryBot.build(:email, kind: 'home')]
      per.phones = [FactoryBot.build(:phone, kind: 'home')]
      per.save!
      per
    end

    let!(:consumer_family) do
      FactoryBot.create(
        :family,
        :with_primary_family_member,
        person: consumer_person
      )
    end

    let!(:broker_person) do
      FactoryBot.create(
        :person,
        :with_broker_role,
        :with_mailing_address,
        :with_work_email,
        :with_work_phone,
        first_name: 'Hasse',
        last_name: 'Timur',
        gender: 'male'
      )
    end
    let(:params) do
      {
        source_hbx_id: broker_person.hbx_id,
        target_hbx_id: consumer_person.hbx_id
      }
    end

    let(:broker_agency_profile) do
      FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile)
    end

    context 'When broker and consumer hbx id passed' do
      it 'should merge broker person' do
        expect(consumer_person.broker_role).to be_blank
        subject.call(params)
        consumer_person.reload
        expect(consumer_person.broker_role).to be_present
      end

      it 'should copy work email' do
        expect(consumer_person.work_email).to be_blank
        subject.call(params)
        consumer_person.reload
        expect(consumer_person.work_email).to be_present
      end

      it 'should copy work phone' do
        expect(consumer_person.work_phone).to be_blank
        subject.call(params)
        consumer_person.reload
        expect(consumer_person.work_phone).to be_present
      end

      it 'should delete broker person' do
        expect(Person.where(id: broker_person.id)).to exist
        subject.call(params)
        expect(Person.where(id: broker_person.id)).not_to exist
      end
    end

    context 'when families exists with broker assigned' do
      let(:person_1) do
        FactoryBot.create(
          :person,
          :with_consumer_role,
          :male,
          first_name: 'john',
          last_name: 'adams',
          dob: 40.years.ago,
          ssn: '472743442'
        )
      end
      let(:family_1) do
        FactoryBot.create(
          :family,
          :with_primary_family_member,
          person: person_1
        )
      end
      let(:person_2) do
        FactoryBot.create(
          :person,
          :with_consumer_role,
          :male,
          first_name: 'jimmy',
          last_name: 'adams',
          dob: 40.years.ago,
          ssn: '472743400'
        )
      end
      let(:family_2) do
        FactoryBot.create(
          :family,
          :with_primary_family_member,
          person: person_2
        )
      end

      before(:each) do
        broker_person.broker_role.update(
          benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id
        )
        family_1.hire_broker_agency(broker_person.broker_role.id)
        family_1.reload
        family_2.hire_broker_agency(broker_person.broker_role.id)
        family_2.reload
      end

      it 'should reassign the broker' do
        writing_agent_old = broker_person.broker_role
        expect(
          Family.where(
            'broker_agency_accounts.writing_agent_id': writing_agent_old.id
          ).count
        ).to eq 2
        expect(writing_agent_old.workflow_state_transitions).to be_present

        subject.call(params)
        consumer_person.reload
        writing_agent_new = consumer_person.broker_role

        expect(Family.by_writing_agent_id(writing_agent_old.id).count).to eq 0
        expect(Family.by_writing_agent_id(writing_agent_new.id).count).to eq 2
        expect(writing_agent_new.workflow_state_transitions).to be_present
      end
    end
  end
end
