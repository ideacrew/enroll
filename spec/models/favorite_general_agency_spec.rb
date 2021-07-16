require 'rails_helper'

RSpec.describe FavoriteGeneralAgency, type: :model do
  let(:general_agency_profile) { FactoryBot.build(:general_agency_profile) }
  let(:broker_role) { FactoryBot.build(:broker_role) }

  let(:valid_params) do
    {
      general_agency_profile_id: general_agency_profile.id,
      broker_role: broker_role
    }
  end

  before do
    EnrollRegistry[:general_agency].feature.stub(:is_enabled).and_return(true)
  end

  context ".new" do
    context "with no arguments" do
      let(:params)  { {} }

      it "should be invalid" do
        expect(FavoriteGeneralAgency.create(**params).valid?).to be_falsey
      end
    end

    context "with no general_agency_profile_id" do
      let(:params) {valid_params.except(:general_agency_profile_id)}

      it "should be invalid" do
        expect(FavoriteGeneralAgency.create(**params).errors[:general_agency_profile_id].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:favorite_general_agency) { FavoriteGeneralAgency.new(**params) }

      it "should save" do
        expect(favorite_general_agency.save).to be_truthy
      end
    end
  end
end
