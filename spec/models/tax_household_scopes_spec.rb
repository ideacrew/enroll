# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxHousehold, type: :model do
  before :all do
    DatabaseCleaner.clean
  end

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:household) { family.active_household }
  let(:system_date) { TimeKeeper.date_of_record }
  let(:retro_tax_household) { FactoryBot.create(:tax_household, :active_previous_year, household: household) }
  let(:current_tax_household) { FactoryBot.create(:tax_household, :active_current_year, household: household) }
  let(:prospective_tax_household) { FactoryBot.create(:tax_household, :active_next_year, household: household) }

  describe '.current_and_prospective_by_year' do
    context 'with retro, current and prospective year thhs' do
      before do
        retro_tax_household
        current_tax_household
        prospective_tax_household
      end

      it 'returns current and prospective tax households' do
        result_thhg_ids = household.tax_households.current_and_prospective_by_year(system_date.year).pluck(:id)
        expect(result_thhg_ids).to include(current_tax_household.id, prospective_tax_household.id)
        expect(result_thhg_ids).not_to include(retro_tax_household.id)
      end
    end
  end
end
