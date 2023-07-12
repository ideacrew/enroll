require 'rails_helper'

describe Effective::Datatables::QuoteDatatable do

  def quote_datatable quote
    quote.broker_role_id=broker_role.id
    quote.save
    Effective::Datatables::QuoteDatatable.broker_role_id = broker_role.id
    quote_table = Effective::Datatables::QuoteDatatable.new
  end

  context "draft_quote_publish_disabled?" do
    context "for draft quotes " do
      let(:broker_role) { FactoryBot.create(:broker_role) }
      let(:quote) { FactoryBot.create(:quote) }
      let(:with_household_and_members) { FactoryBot.create(:quote, :with_household_and_members) }
      let(:with_two_households_and_members) { FactoryBot.create(:quote, :with_two_households_and_members)}

      it "should return disabled if View Published Quote is disable for draft quote" do
        quote.aasm_state = "draft"
        quote.save
        expect(subject.draft_quote_publish_disabled?(quote)).to eq 'disabled'
      end
    end
  end

  context "verify access" do
    subject { Effective::Datatables::QuoteDatatable.new }

    it "allows hbx staff which have the permission" do
      user = double('User', has_hbx_staff_role?: true)
      expect(subject.authorized?(user, nil, nil, nil)).to be_truthy
    end

    it "allows person with broker_role" do
      user = double('User', has_hbx_staff_role?: nil, has_broker_role?: true)
      expect(subject.authorized?(user, nil, nil, nil)).to be_truthy
    end

    it "should not allow person without staff_role or broker_role" do
      user = double('User', has_broker_role?: nil, has_hbx_staff_role?: nil)
      expect(subject.authorized?(user, nil, nil, nil)).to be_falsey
    end
  end
end
