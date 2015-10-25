require 'rails_helper'

RSpec.describe EligibilityDetermination, type: :model, dbclean: :after_each do
  it { should validate_presence_of :determined_on }
  it { should validate_presence_of :max_aptc }
  it { should validate_presence_of :csr_percent_as_integer }

  let(:family)                        { FactoryGirl.create(:family, :with_primary_family_member) }
  let(:household)                     { family.households.first }
  let(:tax_household)                 { FactoryGirl.create(:tax_household, household: household) }
  let(:determined_on)                 { TimeKeeper.datetime_of_record }
  let(:max_aptc)                      { 217.85 }
  let(:csr_percent_as_integer)        { 94 }
  let(:csr_eligibility)               { "csr_94" }
  let(:e_pdc_id)                      { "3110344" }
  let(:premium_credit_strategy_kind)  { "allocated_lump_sum_credit" }


  let(:valid_params){
    {
      tax_household: tax_household,
      determined_on: determined_on,
      max_aptc: max_aptc,
      csr_percent_as_integer: csr_percent_as_integer,
      e_pdc_id: e_pdc_id,
      premium_credit_strategy_kind: premium_credit_strategy_kind,
      }
    }

  context "a new instance" do
    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(EligibilityDetermination.create(**params).valid?).to be_falsey
      end
    end

    context "with no determined on" do
      let(:params) {valid_params.except(:determined_on)}

      it "should fail validation" do
        expect(EligibilityDetermination.create(**params).errors[:determined_on].any?).to be_truthy
      end
     end

    context "with all required attributes" do
      let(:params)                  { valid_params }
      let(:eligibility_determination) { EligibilityDetermination.new(**params) }

      it "should be valid" do
        expect(eligibility_determination.valid?).to be_truthy
      end

      it "should save" do
        expect(eligibility_determination.save).to be_truthy
      end
    end

  end


end
