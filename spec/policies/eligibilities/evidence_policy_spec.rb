# frozen_string_literal: true

# spec/policies/evidence_policy_spec.rb
require 'rails_helper'

RSpec.describe Eligibilities::EvidencePolicy, type: :policy do
  let(:policy) { described_class.new(user, record) }
  let!(:person) { FactoryBot.create(:person, :with_consumer_role) }
  let!(:record_user) {FactoryBot.create(:user, :person => person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { family.family_members.first }
  let!(:application) do
    FactoryBot.create(
      :application,
      family_id: family.id,
      aasm_state: 'determined',
      assistance_year: TimeKeeper.date_of_record.year,
      effective_date: Date.today
    )
  end

  let!(:applicant) do
    applicant = FactoryBot.create(:financial_assistance_applicant,
                                  application: application,
                                  is_primary_applicant: true,
                                  ssn: person.ssn,
                                  dob: person.dob,
                                  first_name: person.first_name,
                                  last_name: person.last_name,
                                  gender: person.gender,
                                  person_hbx_id: person.hbx_id,
                                  family_member_id: family_member.id)
    applicant
  end

  let(:record) do
    applicant.create_esi_evidence(
      key: :esi_mec,
      title: 'Esi',
      aasm_state: 'pending',
      due_on: nil,
      verification_outstanding: false,
      is_satisfied: true
    )
  end

  context 'admin user' do
    let!(:admin_person) { FactoryBot.create(:person, :with_hbx_staff_role) }
    let!(:admin_user) {FactoryBot.create(:user, :with_hbx_staff_role, :person => admin_person)}
    let!(:update_admin) { admin_person.hbx_staff_role.update_attributes(permission_id: permission.id) }
    let(:user) { admin_user }

    context 'with permission' do
      let!(:permission) { FactoryBot.create(:permission, :super_admin) }

      context '#can_upload?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_upload?).to be_truthy
        end
      end

      context '#can_download?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_download?).to be_truthy
        end
      end

      context '#can_destroy?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_destroy?).to be_truthy
        end
      end

      context '#allowed_to_modify?' do
        context 'when the user has the modify_family permission' do

          it 'returns true' do
            expect(policy.send(:allowed_to_modify?)).to be true
          end
        end
      end
    end

    context 'without permission' do
      let!(:permission) { FactoryBot.create(:permission, :developer) }

      context '#can_upload?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_upload?).to be_falsey
        end
      end

      context '#can_download?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_download?).to be_falsey
        end
      end

      context '#can_destroy?' do
        it 'returns the result of #allowed_to_modify?' do
          expect(policy.can_destroy?).to be_falsey
        end
      end

      context '#allowed_to_modify?' do
        context 'when the user has the modify_family permission' do

          it 'returns true' do
            expect(policy.send(:allowed_to_modify?)).to be false
          end
        end
      end
    end
  end

  context 'record user' do
    let(:user) { record_user }

    context '#can_upload?' do
      it 'returns the result of #allowed_to_modify?' do
        expect(policy.can_upload?).to be_truthy
      end
    end

    context '#can_download?' do
      it 'returns the result of #allowed_to_modify?' do
        expect(policy.can_download?).to be_truthy
      end
    end

    context '#can_destroy?' do
      it 'returns the result of #allowed_to_modify?' do
        expect(policy.can_destroy?).to be_truthy
      end
    end

    context '#allowed_to_modify?' do
      context 'when the user has the modify_family permission' do

        it 'returns true' do
          expect(policy.send(:allowed_to_modify?)).to be true
        end
      end
    end
  end

  context 'unauthorized user' do
    let!(:fake_person) { FactoryBot.create(:person, :with_consumer_role) }
    let!(:fake_user) {FactoryBot.create(:user, :person => fake_person)}
    let!(:fake_family) { FactoryBot.create(:family, :with_primary_family_member, person: fake_person) }
    let!(:fake_family_member) { fake_family.family_members.first }
    let(:user) { fake_user }

    context '#can_upload?' do
      it 'returns the result of #allowed_to_modify?' do
        expect(policy.can_upload?).to be_falsey
      end
    end

    context '#can_download?' do
      it 'returns the result of #allowed_to_modify?' do
        expect(policy.can_download?).to be_falsey
      end
    end

    context '#can_destroy?' do
      it 'returns the result of #allowed_to_modify?' do
        expect(policy.can_destroy?).to be_falsey
      end
    end

    context '#allowed_to_modify?' do
      context 'when the user has the modify_family permission' do

        it 'returns true' do
          expect(policy.send(:allowed_to_modify?)).to be false
        end
      end
    end
  end

end