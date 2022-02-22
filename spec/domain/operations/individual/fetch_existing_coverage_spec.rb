# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::Individual::FetchExistingCoverage do
  subject do
    described_class.new.call(params)
  end

  let(:params) do
    { :enrollment_id => hbx_enrollment.hbx_id }
  end

  describe "Not passing params to call the operation" do
    let(:params) { { } }

    it "fails" do
      expect(subject).not_to be_success
      expect(subject.failure).to eq "Given input is not a valid enrollment id"
    end
  end

  describe "passing correct params to call the operation" do

  let!(:person11) do
    FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      :with_ssn,
                      first_name: 'Person11')


  end
  let!(:family11) { FactoryBot.create(:family, :with_primary_family_member_and_dependent, person: person11) }

  let(:dependents) { family11.dependents }

  let!(:person12) do
    person = FactoryBot.create(:person,
                      :with_consumer_role,
                      :with_active_consumer_role,
                      :with_ssn,
                      first_name: 'Person12')
      person.ensure_relationship_with(person11, 'spouse')
    person

  end
  let!(:family12) { FactoryBot.create(:family, :with_primary_family_member, person: person12) }


  let!(:household) { FactoryBot.create(:household, family: family11) }
  let!(:household1) { FactoryBot.create(:household, family: family12) }
  let(:effective_on) {TimeKeeper.date_of_record.beginning_of_year - 1.year}
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
  let(:hbx_en_member1) { FactoryBot.build(:hbx_enrollment_member,
                                            eligibility_date: effective_on,
                                            coverage_start_on: effective_on,
                                            applicant_id: person11.primary_family.family_members.first.id) }
  let(:hbx_en_member2) { FactoryBot.build(:hbx_enrollment_member,
                                        eligibility_date: effective_on,
                                        coverage_start_on: effective_on,
                                        applicant_id: person11.primary_family.family_members.first.id) }
  let(:hbx_en_member3) { FactoryBot.build(:hbx_enrollment_member,
                                    eligibility_date: effective_on + 6.months,
                                    coverage_start_on: effective_on + 6.months,
                                    applicant_id: person12.primary_family.family_members.first.id) }
  let!(:enrollment1) {
    FactoryBot.create(:hbx_enrollment,
                       family: family11,
                       product: product,
                       household: family11.active_household,
                       coverage_kind: "health",
                       effective_on: effective_on,
                       terminated_on: effective_on.next_month.end_of_month,
                       kind: 'individual',
                       hbx_enrollment_members: [hbx_en_member1, hbx_en_member2],
                       aasm_state: 'coverage_selected'
    )}
  let!(:enrollment2) {
    FactoryBot.create(:hbx_enrollment,
                       family: family12,
                       product: product,
                       kind: 'individual',
                       household: family12.active_household,
                       coverage_kind: "health",
                       hbx_enrollment_members: [hbx_en_member3],
                       effective_on: effective_on + 2.months,
                       terminated_on: (effective_on + 5.months).end_of_month,
                       aasm_state: 'shopping'
    )}


    let(:params) do
      { :enrollment_id => enrollment2.id }
    end
    it "Passes" do
      binding.pry
      expect(subject).to be_success
    end
  end
end
