# frozen_string_literal: true

require 'rails_helper'
require 'aasm/rspec'

RSpec.describe ::FinancialAssistance::Application, type: :model, dbclean: :after_each do
  include Dry::Monads[:do, :result]

  let(:person) { FactoryBot.create(:person, :with_consumer_role)}
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let!(:person2) do
    per = FactoryBot.create(:person, :with_consumer_role, dob: Date.today - 30.years)
    person.ensure_relationship_with(per, 'spouse')
    per.addresses.delete_all
    person.save!
    per
  end
  let!(:family_member) { FactoryBot.create(:family_member, family: family, person: person2) }
  let(:product) {double(id: '123', csr_variant_id: '01')}

  let!(:health_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      :individual_assisted,
      family: family,
      applied_aptc_amount: Money.new(44_500),
      consumer_role_id: person.consumer_role.id,
      enrollment_members: family.family_members,
      coverage_kind: "health"
    )
  end

  let!(:dental_enrollment) do
    FactoryBot.create(
      :hbx_enrollment,
      :with_enrollment_members,
      :individual_assisted,
      family: family,
      applied_aptc_amount: Money.new(0),
      consumer_role_id: person.consumer_role.id,
      enrollment_members: family.family_members,
      coverage_kind: "dental"
    )
  end

  let!(:year) { TimeKeeper.date_of_record.year }
  let!(:application) { FactoryBot.create(:financial_assistance_application, family_id: family.id) }
  let!(:eligibility_determination1) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:eligibility_determination2) { FactoryBot.create(:financial_assistance_eligibility_determination, application: application) }
  let!(:applicant1) do
    FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: eligibility_determination1.id, application: application, family_member_id: family.family_members[0].id)
  end
  let!(:applicant2) { FactoryBot.create(:financial_assistance_applicant, eligibility_determination_id: eligibility_determination2.id, application: application, family_member_id: family.family_members[1].id) }

  let(:create_instate_addresses) do
    application.applicants.each do |appl|
      appl.addresses = [FactoryBot.build(:financial_assistance_address,
                                         :address_1 => '1111 Awesome Street NE',
                                         :address_2 => '#111',
                                         :address_3 => '',
                                         :city => 'Washington',
                                         :country_name => '',
                                         :kind => 'home',
                                         :state => FinancialAssistanceRegistry[:enroll_app].setting(:state_abbreviation).item,
                                         :zip => '20001',
                                         county: '')]
      appl.save!
    end
    application.save!
  end

  let(:create_relationships) do
    application.applicants.first.update_attributes!(is_primary_applicant: true) unless application.primary_applicant.present?
    application.ensure_relationship_with_primary(applicant2, 'spouse')
    application.build_relationship_matrix
    application.save!
  end

  before do
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).and_return(false)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:ifsv_determination).and_return(true)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:mec_check).and_return(true)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:esi_mec_determination).and_return(true)
    allow(FinancialAssistanceRegistry).to receive(:feature_enabled?).with(:non_esi_mec_determination).and_return(true)
    allow(health_enrollment).to receive(:product).and_return(product)
    allow(dental_enrollment).to receive(:product).and_return(product)

    applicant1.create_evidences
    applicant1.create_eligibility_income_evidence
    applicant1.income_evidence.move_to_verified!
    applicant2.create_evidences
    applicant2.create_eligibility_income_evidence
    applicant2.income_evidence.move_to_verified!
  end

  context '#enrolled_with' do
    context 'when consumer has both health and dental enrollments' do
      context 'when dental enrollment is passed' do
        it 'should not update income evidence' do
          application.enrolled_with(dental_enrollment)
          applicant1.income_evidence.reload
          expect(applicant1.income_evidence).to be_verified
        end
      end

      context 'when uqhp health enrollment is passed' do
        it 'should set income evidence to negative response received' do
          health_enrollment.update_attributes(applied_aptc_amount: Money.new(0))
          application.enrolled_with(health_enrollment)
          applicant1.income_evidence.reload
          expect(applicant1.income_evidence).to be_negative_response_received
        end
      end

      context 'when aqhp health enrollment is passed' do
        it 'should set income evidence to negative response received' do
          application.enrolled_with(health_enrollment)
          applicant1.income_evidence.reload
          expect(applicant1.income_evidence).to be_verified
        end
      end
    end
  end
end