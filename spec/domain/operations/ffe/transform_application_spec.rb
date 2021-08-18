# frozen_string_literal: true

require 'aca_entities'
require 'aca_entities/ffe/operations/process_mcr_application'
require 'aca_entities/ffe/transformers/mcr_to/family'

RSpec.describe Operations::Ffe::TransformApplication, type: :model, dbclean: :after_each do
  context 'for success flow' do
    before do
      example_input_hash = JSON.parse(File.read(Pathname.pwd.join('spec/test_data/transform_example_payloads/application_test.json')))
      @example_output_hash = JSON.parse(File.read(Pathname.pwd.join('spec/test_data/transform_example_payloads/family_transform_result.json')))
      @result = subject.call(example_input_hash)
    end

    # revisit this spec after migration
    context 'success' do
      # it 'should return success' do
      #   expect(@result).to be_a Dry::Monads::Result::Success
      # end

      # # remove merge after updating aca_entities gem with ext_app_id
      # it 'should return family hash' do
      #   expect(JSON.parse({"ext_app_id": "201868"}.merge(@result.success.to_h).to_json)).to eq @example_output_hash
      # end
    end
  end
end
