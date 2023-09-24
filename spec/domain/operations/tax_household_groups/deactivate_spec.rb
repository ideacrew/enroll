# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::TaxHouseholdGroups::Deactivate, type: :model, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let(:system_date) { TimeKeeper.date_of_record }

  let(:retro_tax_household_group) { FactoryBot.create(:tax_household_group, :active_previous_year, family: family) }
  let(:current_tax_household_group) { FactoryBot.create(:tax_household_group, :active_current_year, family: family) }
  let(:prospective_tax_household_group) { FactoryBot.create(:tax_household_group, :active_next_year, family: family) }

  let(:inactive_retro_thhg) { FactoryBot.create(:tax_household_group, :inactive_previous_year, family: family) }
  let(:inactive_current_thhg) { FactoryBot.create(:tax_household_group, :inactive_current_year, family: family) }
  let(:inactive_prospective_thhg) { FactoryBot.create(:tax_household_group, :inactive_next_year, family: family) }

  subject { described_class.new.call(input_params) }

  describe '#call' do
    let(:invalid_params_failure_message) { 'Invalid params. family should be an instance of Family and new_effective_date should be an instance of Date' }
    let(:no_active_thhgs_message) { 'No Active Tax Household Groups to deactivate' }
    let(:deactivated_thhgs_message) { "Deactivated all the Active tax_household_groups for given family with hbx_id: #{family.hbx_assigned_id}" }

    context 'invalid input params' do
      context 'invalid family' do
        let(:input_params) { { family: nil, new_effective_date: system_date } }

        it 'returns a failure with a message' do
          expect(subject.failure).to eq(invalid_params_failure_message)
        end
      end

      context 'invalid new_effective_date' do
        let(:input_params) { { family: family, new_effective_date: nil } }

        it 'returns a failure with a message' do
          expect(subject.failure).to eq(invalid_params_failure_message)
        end
      end

      context 'invalid family, new_effective_date' do
        let(:input_params) { { family: nil, new_effective_date: nil } }

        it 'returns a failure with a message' do
          expect(subject.failure).to eq(invalid_params_failure_message)
        end
      end
    end

    context 'without tax household groups' do
      let(:input_params) { { family: family, new_effective_date: system_date } }

      it 'returns a success with a message' do
        expect(subject.success).to eq(no_active_thhgs_message)
      end
    end

    context 'without active tax household groups' do
      let(:input_params) { { family: family, new_effective_date: system_date } }

      before do
        inactive_retro_thhg
        inactive_current_thhg
        inactive_prospective_thhg
      end

      it 'returns a success with a message' do
        expect(subject.success).to eq(no_active_thhgs_message)
      end
    end

    context 'with active tax household groups' do
      let(:input_params) { { family: family, new_effective_date: system_date } }

      before do
        retro_tax_household_group
        current_tax_household_group
        prospective_tax_household_group

        inactive_retro_thhg
        inactive_current_thhg
        inactive_prospective_thhg
      end

      it 'returns a success with a message' do
        expect(subject.success).to eq(deactivated_thhgs_message)
      end

      it 'deactivates current and prospective year active thhgs' do
        expect(family.reload.tax_household_groups.active.pluck(:id)).to include(
          current_tax_household_group.id,
          prospective_tax_household_group.id
        )

        subject

        expect(family.reload.tax_household_groups.active.pluck(:id)).to include(retro_tax_household_group.id)

        expect(family.reload.tax_household_groups.inactive.pluck(:id)).to include(
          current_tax_household_group.id,
          prospective_tax_household_group.id
        )
      end
    end
  end
end
