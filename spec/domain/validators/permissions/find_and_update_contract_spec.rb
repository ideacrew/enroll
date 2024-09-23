# frozen_string_literal: true

RSpec.describe Validators::Permissions::FindAndUpdateContract do
  let(:valid_names) { ['hbx_staff', 'super_admin'] }
  let(:invalid_names) { ['invalid_super_admin'] }
  let(:valid_field_name) { :modify_family }
  let(:invalid_field_name) { :invalid_field }
  let(:valid_field_value) { true }
  let(:invalid_field_value) { 'not_a_boolean' }

  describe 'validations' do
    context 'with valid inputs' do
      it 'passes validation' do
        result = subject.call(
          { names: valid_names, field_name: valid_field_name, field_value: valid_field_value }
        )
        expect(result.errors).to be_empty
      end
    end

    context 'with invalid names' do
      it 'fails validation' do
        result = subject.call(
          { names: invalid_names, field_name: valid_field_name, field_value: valid_field_value }
        )
        expect(result.errors[:names][0]).to include(
          'must be one of: hbx_staff, hbx_read_only, hbx_csr_supervisor, hbx_csr_tier1, hbx_csr_tier2, hbx_tier3, developer, super_admin'
        )
      end
    end

    context 'with invalid field_name' do
      it 'fails validation' do
        result = subject.call(
          { names: valid_names, field_name: invalid_field_name, field_value: valid_field_value }
        )

        expect(result.errors[:field_name][0]).to match(
          'must be one of: modify_family, modify_employer, revert_application, list_enrollments, send_broker_agency_message, approve_broker'
        )
      end
    end

    context 'with invalid field_value' do
      it 'fails validation' do
        result = subject.call(
          { names: valid_names, field_name: valid_field_name, field_value: invalid_field_value }
        )
        expect(result.errors[:field_value]).to include('must be boolean')
      end
    end

    context 'with coercion' do
      it 'coerces names to strings' do
        result = subject.call(
          { names: [:hbx_staff, :super_admin], field_name: valid_field_name, field_value: valid_field_value }
        )
        expect(result.errors).to be_empty
      end

      it 'coerces field_name to symbol' do
        result = subject.call(
          { names: valid_names, field_name: 'modify_family', field_value: valid_field_value }
        )
        expect(result.errors).to be_empty
      end
    end
  end
end
