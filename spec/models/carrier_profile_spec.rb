require 'rails_helper'

RSpec.describe CarrierProfile, :type => :model do
  it { should delegate_method(:hbx_id).to :organization }
  it { should delegate_method(:legal_name).to :organization }
  it { should delegate_method(:dba).to :organization }
  it { should delegate_method(:fein).to :organization }
  it { should delegate_method(:is_active).to :organization }
  it { should delegate_method(:updated_by).to :organization }


  let(:organization) {FactoryGirl.create(:organization)}
  let(:abbrev) {"uhc"}

  describe ".new" do

    let(:valid_params) do
      {
        organization: organization,
        abbrev: abbrev,
        issuer_hios_ids: ['11111', '22222']
      }
    end

    context "with no organization" do
      let(:params) {valid_params.except(:organization)}

      it "should raise" do
        expect{CarrierProfile.new(**params).save}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      let(:carrier_profile) {CarrierProfile.new(**params)}

      it "should save" do
        expect(carrier_profile.save).to be_truthy
      end

      it "should not be restricted to single choice" do
        expect(carrier_profile.restricted_to_single_choice?).to be_falsey
      end

      context "and it is saved" do
        before do
          carrier_profile.save
        end

        it "should be findable" do
          expect(CarrierProfile.find(carrier_profile.id).id.to_s).to eq carrier_profile.id.to_s
        end
      end
    end
  end

  describe ".associated_carrier_profile" do
    let(:organization) {FactoryGirl.create(:organization)}
    let(:abbrev) {"uhc"}

    let(:valid_params) do
      {
        organization: organization,
        abbrev: abbrev
      }
    end

    context "with associated_carrier_profile" do
      let(:associated_carrier_profile) {FactoryGirl.create(:carrier_profile)}
      let(:carrier_profile) {CarrierProfile.new(**valid_params)}

      before {associated_carrier_profile}
      before do
        # associated_carrier_profile
        carrier_profile.associated_carrier_profile = associated_carrier_profile
      end

      it "should return associated_carrier_profile" do
        expect(carrier_profile.associated_carrier_profile).to be_a CarrierProfile
        expect(carrier_profile.associated_carrier_profile).to eq associated_carrier_profile
      end

      context "and associated_carrier_profile is removed" do
        before do
          carrier_profile.associated_carrier_profile = ""
        end

        it "should return nil" do
          expect(carrier_profile.associated_carrier_profile).to eq nil
        end
      end
    end
  end
end
