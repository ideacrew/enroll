require 'rails_helper'

RSpec.describe OfficeLocation, :type => :model do

  it { should validate_presence_of :address }

  let(:organization) {FactoryGirl.create(:organization)}
  let(:address) {FactoryGirl.build(:address, kind: 'primary')}
  let(:phone) {FactoryGirl.build(:phone)}
  let(:email) {FactoryGirl.build(:email)}
  let(:is_primary) { true }

  describe ".new" do

    let(:valid_params) do
      {
        organization: organization,
        address: address,
        phone: phone,
        is_primary: is_primary
      }
    end

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(OfficeLocation.new(**params).save).to be_falsey
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}

      it "should save" do
        expect(OfficeLocation.new(**params).save).to be_truthy
        expect(OfficeLocation.new(**params).is_primary?).to be_truthy
      end
    end

    context "with no address" do
      let(:params) {valid_params.except(:address)}

      it "should fail validation" do
        expect(OfficeLocation.create(**params).errors[:address].any?).to be_truthy
      end
    end

    context "with no phone" do
      let(:params) {valid_params.except(:phone)}

      it "should fail validation when primary" do
        expect(OfficeLocation.create(**params).errors[:phone].any?).to be_truthy
      end

      it "should success when mailing" do
        params[:address][:kind] = "mailing"
        expect(OfficeLocation.create(**params).errors[:phone].any?).to be_falsey
        expect(OfficeLocation.new(**params).save).to be_truthy
      end
    end

    context "with no organization" do
      let(:params) {valid_params.except(:organization)}

      it "should raise" do
        expect{OfficeLocation.new(**params).save}.to raise_error(Mongoid::Errors::NoParent)
      end
    end
  end
end
