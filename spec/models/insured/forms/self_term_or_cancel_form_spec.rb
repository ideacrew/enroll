# frozen_string_literal: true.

require 'rails_helper'

module Insured
  RSpec.describe Forms::SelfTermOrCancelForm, type: :model, dbclean: :after_each do

    subject { Insured::Forms::SelfTermOrCancelForm.new }

    describe "model attributes" do
      it {
        [:carrier_logo, :enrollment, :family, :is_aptc_eligible, :market_kind, :product, :term_date].each do |key|
          expect(subject.attributes.key?(key)).to be_truthy
        end
      }
    end

    describe "validate Form" do

      let(:valid_params) do
        {
          :market_kind => "kind"
        }
      end

      let(:invalid_params) do
        {
          :market_kind => nil
        }
      end

      context "with invalid params" do

        let(:build_self_term_or_cancel_form) { Insured::Forms::SelfTermOrCancelForm.new(invalid_params)}

        it "should return false" do
          expect(build_self_term_or_cancel_form.valid?).to be_falsey
        end
      end

      context "with valid params" do

        let(:build_self_term_or_cancel_form) { Insured::Forms::SelfTermOrCancelForm.new(valid_params)}

        it "should return true" do
          expect(build_self_term_or_cancel_form.valid?).to be_truthy
        end
      end
    end

    describe "#for_view" do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
      let(:sep) { FactoryBot.create(:special_enrollment_period, family: family) }
      let(:sbc_document) { FactoryBot.build(:document, subject: "SBC", identifier: "urn:openhbx#123") }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :with_issuer_profile, title: "AAA", sbc_document: sbc_document) }
      let(:enrollment) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product) }

      it "should create a valid form for the view" do
        family.special_enrollment_periods << sep
        attrs = {enrollment_id: enrollment.id.to_s, family_id: family.id}
        form = Insured::Forms::SelfTermOrCancelForm.for_view(attrs)
        expect(Insured::Forms::SelfTermOrCancelForm.self_term_or_cancel_service(attrs)).to be_instance_of(Insured::Services::SelfTermOrCancelService)
        expect(form.enrollment).not_to be nil
        expect(form.family).not_to be nil
        expect(form.product).not_to be nil
      end
    end

    describe "#for_post" do
      let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
      let(:sep) {FactoryBot.create(:special_enrollment_period, family: family) }
      let(:sbc_document) { FactoryBot.build(:document, subject: "SBC", identifier: "urn:openhbx#124") }
      let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, title: "AAA", issuer_profile_id: "ab1233", sbc_document: sbc_document) }
      let(:enrollment_to_cancel) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today + 1.month) }
      let(:enrollment_to_term) { FactoryBot.create(:hbx_enrollment, :individual_unassisted, family: family, product: product, effective_on: Date.today - 1.month) }

      it "should cancel an enrollment if it is not yet effective" do
        attrs = {enrollment_id: enrollment_to_cancel.id, term_date: TimeKeeper.date_of_record.to_s}
        Insured::Forms::SelfTermOrCancelForm.for_post(attrs)
        enrollment_to_cancel.reload
        expect(enrollment_to_cancel.aasm_state).to eq 'coverage_canceled'
      end

      it "should terminate an enrollment if it is already effective" do
        attrs = {enrollment_id: enrollment_to_term.id, term_date: (TimeKeeper.date_of_record + 1.month).to_s}
        Insured::Forms::SelfTermOrCancelForm.for_post(attrs)
        enrollment_to_term.reload
        expect(enrollment_to_term.aasm_state).to eq 'coverage_terminated'
      end
    end

  end
end
