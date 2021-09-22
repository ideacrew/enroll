# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Notices::IvlDocumentReminderNoticeTrigger, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'ivl document reminder notice trigger' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:issuer) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM') }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, issuer_profile: issuer) }
    let(:enrollment) do
      FactoryBot.create(
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
      let(:params) {{}}

      it 'should return failure' do
        result = subject.call(params)
        expect(result.failure?).to be_truthy
        expect(result.failure).to eq 'Missing family'
      end
    end

    context 'with valid params' do
      before :each do
        person.consumer_role.verification_types.each {|vt| vt.update_attributes(validation_status: 'outstanding', due_date: TimeKeeper.date_of_record - 1.day)}
        allow_any_instance_of(Events::Individual::Enrollments::FirstVerificationsReminder).to receive(:publish).and_return true
      end

      let(:params) {{family: family, event_name: 'first_verifications_reminder'}}

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end
    end

    context 'with valid params when in special enrollment period' do
      let(:qualifying_life_event_kind) { FactoryBot.create(:qualifying_life_event_kind, start_on: Date.today.prev_day) }
      let!(:sep) { FactoryBot.create(:special_enrollment_period, family: family, qualifying_life_event_kind: qualifying_life_event_kind) }

      before :each do
        enrollment.update_attributes(enrollment_kind: 'special_enrollment')
        person.consumer_role.verification_types.each {|vt| vt.update_attributes(validation_status: 'outstanding', due_date: TimeKeeper.date_of_record - 1.day)}
        allow_any_instance_of(Events::Individual::Enrollments::FirstVerificationsReminder).to receive(:publish).and_return true
      end

      let(:params) {{family: family, event_name: 'first_verifications_reminder'}}

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end
    end
  end
end
