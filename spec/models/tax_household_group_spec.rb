# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHouseholdGroup, type: :model do
  before :all do
    DatabaseCleaner.clean
  end

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:system_date) { TimeKeeper.date_of_record }
  let(:retro_tax_household_group) { FactoryBot.create(:tax_household_group, :active_previous_year, family: family) }
  let(:current_tax_household_group) { FactoryBot.create(:tax_household_group, :active_current_year, family: family) }
  let(:prospective_tax_household_group) { FactoryBot.create(:tax_household_group, :active_next_year, family: family) }

  describe '.current_and_prospective_by_year' do
    context 'with retro, current and prospective year thhgs' do
      before do
        retro_tax_household_group
        current_tax_household_group
        prospective_tax_household_group
      end

      it 'returns current and prospective tax household groups' do
        result_thhg_ids = family.tax_household_groups.current_and_prospective_by_year(system_date.year).pluck(:id)
        expect(result_thhg_ids).to include(current_tax_household_group.id, prospective_tax_household_group.id)
        expect(result_thhg_ids).not_to include(retro_tax_household_group.id)
      end
    end
  end
end
