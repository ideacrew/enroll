# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Families::TerminateBrokerAgency, dbclean: :after_each do

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :male, first_name: 'john', last_name: 'adams', dob: 40.years.ago, ssn: '472743442') }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:broker_agency_profile) { FactoryBot.build(:benefit_sponsors_organizations_broker_agency_profile)}
  let(:writing_agent)         { FactoryBot.create(:broker_role, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id) }

  describe 'broker agency account term params for family' do

    before(:each) do
      family.hire_broker_agency(writing_agent.id)
      family.reload
    end

    context 'when valid params passed' do
      it 'should terminate broker agency account' do
        expect(family.current_broker_agency.writing_agent).to eq writing_agent
        terminate_params = { family_id: family.id,
                             terminate_date: TimeKeeper.date_of_record,
                             broker_account_id: family.current_broker_agency&.id }

        result = subject.call(terminate_params)
        expect(result).to be_a(Dry::Monads::Result::Success)
        expect(result.success).to eq true
        family.reload
        expect(family.current_broker_agency).to eq nil
      end
    end

    context 'when invalid params passed' do
      it 'should return failure' do
        terminate_params = { family_id: family.id,
                             terminate_date: TimeKeeper.date_of_record,
                             broker_account_id: BSON::ObjectId.new }
        result = subject.call(terminate_params)
        expect(result).to be_a(Dry::Monads::Result::Failure)
        expect(result.failure.messages.map(&:text)).to eq ["invalid broker_account_id"]
      end
    end
  end
end