# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Households::CheckExistingCoverageByPerson, db_clean: :after_each do
  subject do
    described_class.new.call(params)
  end

  context "call the operation" do
    let!(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person)}
    let!(:primary) { family.primary_family_member }
    let!(:dependents) { family.dependents }
    let!(:household) { FactoryBot.create(:household, family: family) }
    let!(:effective_on) {TimeKeeper.date_of_record.beginning_of_year - 1.year}
    let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
    let!(:hbx_en_member1) do
      FactoryBot.build(:hbx_enrollment_member,
                       eligibility_date: effective_on,
                       coverage_start_on: effective_on,
                       applicant_id: primary.id)
    end

    let!(:hbx_en_member2) do
      FactoryBot.build(:hbx_enrollment_member,
                       eligibility_date: effective_on,
                       coverage_start_on: effective_on,
                       applicant_id: dependents.first.id)
    end

    let!(:enrollment1) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: effective_on,
                        kind: 'employer_sponsored',
                        hbx_enrollment_members: [hbx_en_member1, hbx_en_member2],
                        aasm_state: 'coverage_selected')
    end
    let!(:enrollment2) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product,
                        kind: 'employer_sponsored',
                        household: family.active_household,
                        coverage_kind: "health",
                        hbx_enrollment_members: [hbx_en_member1],
                        effective_on: effective_on + 2.months,
                        aasm_state: 'shopping')
    end
    let!(:enrollment3) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: effective_on + 6.months,
                        kind: 'individual',
                        hbx_enrollment_members: [hbx_en_member1, hbx_en_member2],
                        aasm_state: 'coverage_selected')
    end
    let!(:enrollment4) do
      FactoryBot.create(:hbx_enrollment,
                        family: family,
                        product: product,
                        household: family.active_household,
                        coverage_kind: "health",
                        effective_on: effective_on + 6.months,
                        kind: 'employer_sponsored',
                        hbx_enrollment_members: [hbx_en_member2],
                        aasm_state: 'coverage_selected')
    end

    let!(:params) do
      { :person_hbx_id => person.hbx_id, market_kind: 'employer_sponsored' }
    end

    context "Not passing params to call the operation" do
      let!(:params) { { } }

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "id is nil or not in BSON format"
      end
    end

    context "passing incorrect params to call the operation" do
      let!(:params) { { :person_hbx_id => 'abc123' } }

      it "fails" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "Unable to find Person with ID abc123."
      end
    end

    context "passing person id with no families associated" do
      before :each do
        family.family_members.first.person_id = nil
        family.family_members.first.save(validate: false)
      end

      it "returns failure" do
        expect(subject).not_to be_success
        expect(subject.failure).to eq "No families found for person"
      end
    end

    context "passing shop enrollment as input returns shop related enrollments" do
      it "returns failure" do
        expect(subject).to be_success
        expect(subject.success.flatten).to eq [enrollment1]
      end
    end
  end
end
