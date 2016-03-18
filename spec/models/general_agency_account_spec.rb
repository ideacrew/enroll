require 'rails_helper'

RSpec.describe GeneralAgencyAccount, type: :model do
  let(:employer_profile)      { FactoryGirl.create(:employer_profile)}
  let(:general_agency_profile) { FactoryGirl.build(:general_agency_profile) }
  let(:start_on)              { TimeKeeper.date_of_record }

  let(:valid_params) do
    {
      employer_profile: employer_profile,
      general_agency_profile: general_agency_profile,
      start_on: start_on
    }
  end

  context ".new" do
    context "with no arguments" do
      let(:params)  { {} }
      let(:general_agency_account) {GeneralAgencyAccount.new(**params)}

      it "should be invalid" do
        expect(GeneralAgencyAccount.create(**params).valid?).to be_falsey
      end
    end

    context "with no start_on" do
      let(:params) {valid_params.except(:start_on)}

      it "should be invalid" do
        expect(GeneralAgencyAccount.create(**params).errors[:start_on].any?).to be_truthy
      end
    end

    context "with no general_agency_profile" do
      let(:params) {valid_params.except(:general_agency_profile)}

      it "should be invalid" do
        expect(GeneralAgencyAccount.create(**params).errors[:general_agency_profile_id].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:general_agency_account) { GeneralAgencyAccount.new(**params) }

      it "should save" do
        expect(general_agency_account.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_general_agency_account) do
          gaa = general_agency_account
          gaa.save!
          gaa
        end

        it "and should be findable by ID" do
          expect(GeneralAgencyAccount.find(saved_general_agency_account.id)._id).to eq saved_general_agency_account.id
        end
      end
    end
  end
end
