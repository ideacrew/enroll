# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Permissions::FindAndUpdate do

  after :each do
    DatabaseCleaner.clean
  end

  describe '#call' do
    context 'invalid params' do
      let(:input_params) do
        {
          names: ['dummy_hbx_staff', 'super_admin'],
          field_name: 'modify_family',
          field_value: true
        }
      end

      it 'returns a failure' do
        expect(
          subject.call(input_params).failure
        ).to eq(
          {
            names: {
              0 => ['must be one of: hbx_staff, hbx_read_only, hbx_csr_supervisor, hbx_csr_tier1, hbx_csr_tier2, hbx_tier3, developer, super_admin']
            }
          }
        )
      end
    end

    context 'permission not found' do
      let(:input_params) do
        {
          names: ['hbx_staff', 'super_admin'],
          field_name: 'modify_family',
          field_value: true
        }
      end

      it 'returns unable process results' do
        expect(
          subject.call(input_params).success
        ).to eq(
          {
            'hbx_staff' => 'Unable to find permission with given name: hbx_staff',
            'super_admin' => 'Unable to find permission with given name: super_admin'
          }
        )
      end
    end

    context 'permission already has same value' do
      let(:hbx_csr_tier1_permission) { FactoryBot.create(:permission, name: 'hbx_csr_tier1', modify_family: false) }

      let(:input_params) do
        {
          names: [hbx_csr_tier1_permission.name],
          field_name: 'modify_family',
          field_value: false
        }
      end

      it 'returns unable process results' do
        expect(
          subject.call(input_params).success
        ).to eq(
          { 'hbx_csr_tier1' => 'Permission with name: hbx_csr_tier1 already has modify_family set to false' }
        )
      end
    end

    context 'successfully updates the permission that is found' do
      let(:super_admin_permission) { FactoryBot.create(:permission, name: 'super_admin', modify_family: false) }

      let(:input_params) do
        {
          names: ['hbx_staff', super_admin_permission.name],
          field_name: 'modify_family',
          field_value: true
        }
      end

      it 'returns success message' do
        expect(super_admin_permission.modify_family).to eq(false)

        expect(
          subject.call(input_params).success
        ).to eq(
          {
            'hbx_staff' => 'Unable to find permission with given name: hbx_staff',
            super_admin_permission.name => "Permission with name: #{super_admin_permission.name} updated successfully with modify_family to true"
          }
        )

        expect(super_admin_permission.reload.modify_family).to eq(true)
      end
    end

    context 'successfully updates all the permissions' do
      let(:hbx_csr_tier2_permission) { FactoryBot.create(:permission, name: 'hbx_csr_tier2', modify_family: false) }
      let(:hbx_tier3_permission) { FactoryBot.create(:permission, name: 'hbx_tier3', modify_family: false) }

      let(:input_params) do
        {
          names: [hbx_tier3_permission.name, hbx_csr_tier2_permission.name],
          field_name: 'modify_family',
          field_value: true
        }
      end

      it 'returns success message' do
        expect(hbx_csr_tier2_permission.modify_family).to eq(false)
        expect(hbx_tier3_permission.modify_family).to eq(false)

        expect(
          subject.call(input_params).success
        ).to eq(
          {
            hbx_csr_tier2_permission.name => "Permission with name: #{hbx_csr_tier2_permission.name} updated successfully with modify_family to true",
            hbx_tier3_permission.name => "Permission with name: #{hbx_tier3_permission.name} updated successfully with modify_family to true"
          }
        )

        expect(hbx_csr_tier2_permission.reload.modify_family).to eq(true)
        expect(hbx_tier3_permission.reload.modify_family).to eq(true)
      end
    end
  end
end
