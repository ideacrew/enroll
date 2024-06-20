# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Person, type: :model do
  describe '#all_active_role_names' do
    let(:person) { FactoryBot.create(:person) }

    before do
      allow(person).to receive(:assister_role).and_return(double('AssisterRole', present?: true))
      allow(person).to receive(:active_broker_role?).and_return(true)
      allow(person).to receive(:has_active_broker_staff_role?).and_return(false)
      allow(person).to receive(:active_consumer_role?).and_return(true)
      allow(person).to receive(:csr_role).and_return(double('CsrRole', present?: false))
      allow(person).to receive(:has_active_employee_role?).and_return(true)
      allow(person).to receive(:has_active_employer_staff_role?).and_return(false)
      allow(person).to receive(:has_active_general_agency_staff_role?).and_return(true)
      allow(person).to receive(:hbx_staff_role).and_return(double('HbxStaffRole', present?: true))
      allow(person).to receive(:active_resident_role?).and_return(false)
    end

    it 'returns an array of all active roles' do
      expect(person.all_active_role_names).to match_array(
        [
          l10n('user_roles.assister'),
          l10n('user_roles.broker'),
          l10n('user_roles.consumer'),
          l10n('user_roles.employee'),
          l10n('user_roles.general_agency_staff'),
          l10n('user_roles.hbx_staff')
        ]
      )
    end

    it 'caches the result to avoid recalculating' do
      expect(person).to receive(:role_names_based_on_status_of_roles).once.and_call_original
      2.times { person.all_active_role_names }
    end
  end
end
