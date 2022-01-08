# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::Notices::BuildCvPayload,
               type: :model,
               dbclean: :after_each do
  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'build familuy cv payload' do
    let!(:person1) do
      FactoryBot.create(
        :person,
        :with_consumer_role,
        :with_active_consumer_role,
        first_name: 'test10',
        last_name: 'test30',
        gender: 'male'
      )
    end

    let!(:person2) do
      person =
        FactoryBot.create(
          :person,
          :with_consumer_role,
          :with_active_consumer_role,
          first_name: 'test',
          last_name: 'test10',
          gender: 'male'
        )
      person1.ensure_relationship_with(person, 'child')
      person
    end

    let!(:family) do
      FactoryBot.create(:family, :with_primary_family_member, person: person1)
    end

    let!(:family_member) do
      FactoryBot.create(:family_member, family: family, person: person2)
    end

    let(:household) { FactoryBot.create(:household, family: family) }

    let(:issuer) do
      create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM')
    end
    let(:product) do
      create(
        :benefit_markets_products_health_products_health_product,
        :ivl_product,
        issuer_profile: issuer
      )
    end

    let!(:hbx_enrollment1) do
      FactoryBot.create(
        :hbx_enrollment,
        :with_enrollment_members,
        enrollment_members: family.family_members,
        kind: 'individual',
        product: product,
        household: family.latest_household,
        effective_on: TimeKeeper.date_of_record.beginning_of_year,
        enrollment_kind: 'open_enrollment',
        family: family,
        aasm_state: 'coverage_selected',
        consumer_role: person1.consumer_role,
        enrollment_signature: true
      )
    end

    context 'with invalid params' do
      let(:params) { {} }

      it 'should return failure' do
        result = subject.call(params)
        expect(result.failure?).to be_truthy
        expect(result.failure).to include 'family missing'
      end
    end

    context 'with valid params' do
      before :each do
        person1.consumer_role.verification_types.each do |vt|
          vt.update_attributes(
            validation_status: 'outstanding',
            due_date: TimeKeeper.date_of_record - 1.day
          )
        end

        # ::Operations::Eligibilities::BuildFamilyDetermination.new.call(
        #   family: family,
        #   effective_date: TimeKeeper.date_of_record
        # )
      end

      let(:params) { { family: family } }

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end
    end
  end
end
