# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Notices::IvlEnrNoticeTrigger, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'ivl enrollment notice trigger' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:issuer) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, abbrev: 'ANTHM') }
    let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product, issuer_profile: issuer) }
    let(:aasm_state) { 'coverage_selected' }
    let(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        :with_enrollment_members,
        :individual_unassisted,
        family: family,
        aasm_state: aasm_state,
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
        expect(result.failure).to eq 'Missing Enrollment'
      end
    end

    context 'with valid params' do
      before :each do
        person.consumer_role.verification_types.each {|vt| vt.update_attributes(validation_status: 'outstanding', due_date: TimeKeeper.date_of_record - 1.day)}
        allow_any_instance_of(Events::Individual::Enrollments::Submitted).to receive(:publish).and_return true
      end

      let(:params) {{enrollment: enrollment}}

      it 'should return success' do
        result = subject.call(params)
        expect(result.success?).to be_truthy
      end

      context 'when an auto renewing enrollment is present' do
        let(:aasm_state) { 'auto_renewing' }

        it 'should return sucess' do
          result = subject.call(params)
          expect(result.success?).to be_truthy
        end
      end
    end

    context '#build_family_member_hash' do
      let(:person_2) { FactoryBot.create(:person, :with_consumer_role) }
      let!(:family_member_2) { FactoryBot.create(:family_member, person: person_2, family: family)}
      let(:family_members_hash) { Operations::Notices::IvlEnrNoticeTrigger.new.build_family_member_hash(enrollment.reload) }

      it 'should include unerolled family members' do
        expect(family_members_hash.success.count).to eq 2
        expect(family_members_hash.success.any? { |member_hash| member_hash[:person][:person_name][:first_name] == person_2.first_name }).to be_truthy
      end

      it 'should include contact method' do
        expect(family_members_hash.success.all? { |member_hash| member_hash[:person][:consumer_role][:contact_method].present? }).to be_truthy
      end
    end

    context '#build_household_hash' do
      let(:person_2) { FactoryBot.create(:person, :with_consumer_role) }
      let!(:family_member_2) { FactoryBot.create(:family_member, person: person_2, family: family)}
      let(:households_hash) { Operations::Notices::IvlEnrNoticeTrigger.new.build_household_hash(enrollment.reload.family, enrollment) }

      it 'should include timestamp' do
        expect(households_hash.success.count).to eq 1
        expect(households_hash.success.all? { |household_hash| household_hash[:hbx_enrollments][0][:timestamp][:submitted_at].present? }).to be_truthy
      end
    end

    context '#build_family_member_hash with deleted family member' do
      let(:person_2) { FactoryBot.create(:person, :with_consumer_role) }
      let!(:family_member_2) { FactoryBot.create(:family_member, person: person_2, family: family)}
      let(:family_members_hash) { Operations::Notices::IvlEnrNoticeTrigger.new.build_family_member_hash(enrollment.reload) }

      it 'shouldnt include deleted family members' do
        enrollment.family.family_members.last.is_active = false
        enrollment.family.family_members.last.person.addresses = []
        enrollment.family.family_members.last.save!
        expect(family_members_hash.success.count).to eq 1
      end
    end

    context 'with valid params when in special enrollment period' do
      let(:qualifying_life_event_kind) { FactoryBot.create(:qualifying_life_event_kind, start_on: Date.today.prev_day) }
      let!(:sep) { FactoryBot.create(:special_enrollment_period, family: family, qualifying_life_event_kind: qualifying_life_event_kind) }

      before :each do
        person.consumer_role.verification_types.each {|vt| vt.update_attributes(validation_status: 'outstanding', due_date: TimeKeeper.date_of_record - 1.day)}
        allow_any_instance_of(Events::Individual::Enrollments::Submitted).to receive(:publish).and_return true
      end

      context 'latest sep on family' do
        let(:params) {{ enrollment: enrollment }}

        before :each do
          enrollment.update_attributes(enrollment_kind: 'special_enrollment')
        end

        it 'should return success' do
          result = subject.call(params)
          expect(result.success?).to be_truthy
        end
      end

      context 'sep from enrollment' do
        let(:params) {{ enrollment: enrollment }}

        before :each do
          enrollment.update_attributes(enrollment_kind: 'special_enrollment', special_enrollment_period_id: sep.id)
        end

        it 'should return success' do
          result = subject.call(params)
          expect(result.success?).to be_truthy
        end
      end
    end
  end
end
