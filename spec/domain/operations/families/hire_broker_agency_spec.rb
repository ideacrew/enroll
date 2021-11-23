# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Families::HireBrokerAgency, dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :male, first_name: 'john', last_name: 'adams', dob: 40.years.ago, ssn: '472743442') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile)}
  let(:writing_agent)         { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }
  let(:broker_agency_profile2) { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile)}
  let(:writing_agent2)         { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile2.id) }

  describe 'broker agency account hire params for family' do
    context 'when valid params passed' do
      it 'should create broker agency for family' do
        hire_params = { family_id: family.id,
                        terminate_date: TimeKeeper.date_of_record,
                        broker_role_id: writing_agent.id,
                        start_date: TimeKeeper.datetime_of_record,
                        current_broker_account_id: family&.current_broker_agency&.id }

        result = subject.call(hire_params)
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.success).to eq true
        family.reload
        expect(family.current_broker_agency.writing_agent).to eq writing_agent
      end
    end

    context 'rehiring same active broker' do
      before(:each) do
        family.hire_broker_agency(writing_agent.id)
        family.reload
      end

      it 'should not create broker agency' do
        expect(family.broker_agency_accounts.unscoped.length).to eq(1)
        hire_params = { family_id: family.id,
                        terminate_date: TimeKeeper.date_of_record,
                        broker_role_id: writing_agent.id,
                        start_date: TimeKeeper.datetime_of_record,
                        current_broker_account_id: family&.current_broker_agency&.id }

        result = subject.call(hire_params)
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.success).to eq true
        family.reload
        expect(family.broker_agency_accounts.unscoped.length).to eq(1)
      end
    end

    context 'hiring new broker' do
      before(:each) do
        family.hire_broker_agency(writing_agent.id)
        family.reload
      end

      it 'should termiante old broker and create broker agency account for new broker' do
        expect(family.broker_agency_accounts.unscoped.length).to eq(1)
        hire_params = { family_id: family.id,
                        terminate_date: TimeKeeper.date_of_record,
                        broker_role_id: writing_agent2.id,
                        start_date: TimeKeeper.datetime_of_record,
                        current_broker_account_id: family&.current_broker_agency&.id }

        result = subject.call(hire_params)
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.success).to eq true
        family.reload
        expect(family.broker_agency_accounts.unscoped.length).to eq(2)
      end
    end

    context 'when invalid params passed' do
      it 'should return failure' do
        hire_params = { family_id: family.id,
                        terminate_date: TimeKeeper.date_of_record,
                        broker_role_id: BSON::ObjectId.new,
                        start_date: TimeKeeper.datetime_of_record,
                        current_broker_account_id: BSON::ObjectId.new }

        result = subject.call(hire_params)
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure.messages.map(&:text)).to eq ["invalid broker_role_id", "missing benefit_sponsors_broker_agency_profile_id in broker role", "invalid broker_account_id"]
      end
    end
  end
end