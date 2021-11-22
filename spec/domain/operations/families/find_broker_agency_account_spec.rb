# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Families::FindBrokerAgencyAccount, dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :male, first_name: 'john', last_name: 'adams', dob: 40.years.ago, ssn: '472743442') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile)}
  let(:writing_agent)         { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }

  describe 'broker agency account find' do

    before(:each) do
      family.hire_broker_agency(writing_agent.id)
      family.reload
    end

    context 'when broker_account_id passed' do
      it 'should return family broker agency account' do
        result = subject.call({broker_account_id: family.current_broker_agency.id, family_id: family.id})
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.success).to eq family.current_broker_agency
      end
    end

    context 'when invalid params passed' do
      it 'should return failure' do
        result = subject.call({broker_account_id: family.current_broker_agency.id})
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq "Invalid params for BrokerAgencyAccount"
      end

      it 'should return failure' do
        family_id = BSON::ObjectId.new
        result = subject.call({broker_account_id: family.current_broker_agency.id, family_id: family_id})
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure).to eq "Unable to find BrokerAgencyAccount with ID #{family.current_broker_agency.id} for Family #{family_id}."
      end
    end
  end
end