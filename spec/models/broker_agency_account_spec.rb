require 'rails_helper'

RSpec.describe BrokerAgencyAccount, type: :model do
  it { should validate_presence_of :broker_agency_profile_id }
  it { should validate_presence_of :start_on }
  it { should validate_presence_of :is_active }

  let(:employer_profile)      { FactoryBot.create(:employer_profile)}
  let(:broker_agency_profile) { FactoryBot.build(:broker_agency_profile) }
  let(:start_on)              { TimeKeeper.date_of_record }
  let(:writing_agent)         { FactoryBot.build(:broker_role) }

  let(:valid_params) do
    {
      employer_profile: employer_profile,
      broker_agency_profile: broker_agency_profile,
      start_on: start_on
    }
  end

  context ".new" do
    context "with no arguments" do
      let(:params)  { {} }
      let(:broker_agency_account) {BrokerAgencyAccount.new(**params)}

      it "should be invalid" do
        expect(BrokerAgencyAccount.create(**params).valid?).to be_falsey
      end
    end

    context "with no start_on" do
      let(:params) {valid_params.except(:start_on)}

      it "should be invalid" do
        expect(BrokerAgencyAccount.create(**params).errors[:start_on].any?).to be_truthy
      end
    end

    context "with no broker_agency_profile" do
      let(:params) {valid_params.except(:broker_agency_profile)}

      it "should be invalid" do
        expect(BrokerAgencyAccount.create(**params).errors[:broker_agency_profile_id].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:broker_agency_account) { BrokerAgencyAccount.new(**params) }

      it "should save" do
        expect(broker_agency_account.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_broker_agency_account) do
          baa = broker_agency_account
          baa.save!
          baa
        end

        it "and should be findable by ID" do
          expect(BrokerAgencyAccount.find(saved_broker_agency_account.id)._id).to eq saved_broker_agency_account.id
        end

      end
    end
  end

end
