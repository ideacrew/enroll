# frozen_string_literal: true

require 'rails_helper'
RSpec.describe ::Operations::Eligibilities::Notices::RequestDocumentReminderNotices,
               type: :model,
               dbclean: :after_each do
  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'Create reminder request' do
    let(:person) { create(:person, :with_consumer_role) }
    let(:family) do
      create(:family, :with_primary_family_member, person: person)
    end
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
    let(:enrollment) do
      create(
        :hbx_enrollment,
        :with_enrollment_members,
        :individual_unassisted,
        family: family,
        product_id: product.id,
        applied_aptc_amount: Money.new(44_500),
        consumer_role_id: person.consumer_role.id,
        enrollment_members: family.family_members
      )
    end

    context 'with invalid params' do
      let(:params) { {} }

      it 'should return failure' do
        result = subject.call(params)
        expect(result.failure?).to be_truthy
        expect(result.failure).to include 'date of record missing'
      end

      context 'when invalid date format is passed in' do
        let(:params) { { date_of_record: Date.today.to_s } }

        it 'should return failure' do
          result = subject.call(params)
          expect(result.failure?).to be_truthy
          expect(result.failure).to include 'date of record should be an instance of Date'
        end
      end
    end

    context 'with valid params' do
      before :each do
        person.consumer_role.verification_types.each do |vt|
          vt.update_attributes(
            validation_status: 'outstanding',
            due_date: TimeKeeper.date_of_record - 1.day
          )
        end

        allow(Family).to receive(:outstanding_verifications_expiring_on)
          .and_call_original
        allow(Family).to receive(:outstanding_verifications_expiring_on)
          .with(Date.today + 93.days)
          .and_return([family])
      end

      let(:params) { { date_of_record: Date.today } }

      let(:reminder_notices) do
        EnrollRegistry[:ivl_eligibility_notices].settings(:document_reminders)
                                                .item
      end

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end

      it 'should return results with reminder notice keys' do
        result = subject.call(params)
        payload = result.success.payload

        reminder_notices.each do |notice_key|
          expect(payload.key?(notice_key)).to be_truthy
        end
      end
    end
  end
end
