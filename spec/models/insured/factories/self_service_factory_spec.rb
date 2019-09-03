# frozen_string_literal: true

require 'rails_helper'

module Insured
  RSpec.describe Factories::SelfServiceFactory, type: :model, dbclean: :after_each do

    subject { Insured::Factories::SelfServiceFactory }

    describe "view methods" do
      let(:family) { FactoryBot.create(:individual_market_family) }
      let(:sep) { FactoryBot.create(:special_enrollment_period, family: family) }
      let(:sbc_document) { FactoryBot.build(:document, subject: "SBC", identifier: "urn:openhbx#123") }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, title: "AAA", issuer_profile_id: "ab1233", sbc_document: sbc_document) }
      let(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product) }

      context "#find" do
        before :each do
          family.special_enrollment_periods << sep
          # binding.pry
          @enrollment_id = enrollment.id
          @family_id     = family.id
          @qle           = QualifyingLifeEventKind.find(BSON::ObjectId.from_string(sep.qualifying_life_event_kind_id))
          @form_params   = subject.find(@enrollment_id, @family_id)
        end

        it "returns a hash of valid params" do
          expect(@form_params[:enrollment]).to eq enrollment
          expect(@form_params[:family]).to eq family
          expect(@form_params[:qle]).to eq @qle
        end

        it "returns a falsey is_aptc_eligible if latest_active_tax_household does not exist" do
          expect(@form_params[:is_aptc_eligible]).to be_falsey
        end

        it "returns a truthy is_aptc_eligible if tax household and valid aptc members exist" do
          tax_household = FactoryBot.create(:tax_household, household: family.active_household)
          aptc_member   = FactoryBot.create(:tax_household_member, tax_household: tax_household)
          form_params   = subject.find(@enrollment_id, @family_id)
          expect(form_params[:is_aptc_eligible]).to be_truthy
        end
      end
    end

    describe "post methods" do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
      let(:sep) { FactoryBot.create(:special_enrollment_period, family: family) }
      let(:sbc_document) { FactoryBot.build(:document, subject: "SBC", identifier: "urn:openhbx#123") }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, title: "AAA", issuer_profile_id: "ab1233", sbc_document: sbc_document) }
      let(:enrollment_to_cancel) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today + 1.month) }
      let(:enrollment_to_term) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today - 1.month) }

      context "#term_or_cancel" do
        it "should cancel an enrollment if it is not yet effective" do
          subject.term_or_cancel(enrollment_to_cancel.id, TimeKeeper.date_of_record, 'cancel')
          enrollment_to_cancel.reload
          expect(enrollment_to_cancel.aasm_state).to eq 'coverage_canceled'
        end

        it "should terminate an enrollment if it is already effective" do
          subject.term_or_cancel(enrollment_to_term.id, TimeKeeper.date_of_record, 'terminate')
          enrollment_to_term.reload
          expect(enrollment_to_term.aasm_state).to eq 'coverage_terminated'
        end
      end
    end

  end
end
