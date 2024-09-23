# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Permissions
    # Operation to find the permission by name and update permissions based on the field and value
    class FindAndUpdate
      include Dry::Monads[:do, :result]

      # Contract
      #  params: :names, :field, :value
      #
      # @param [Hash] params The parameters for finding and updating permissions
      # @option params [Array<String>] :names The names of the permissions to update
      # @option params [String] :field The field to update
      # @option params [String] :value The value to update the field with
      # @return [Dry::Monads::Result] The result of the operation
      def call(params)
        validated_params  = yield validate(params)
        results           = yield process_updates(validated_params)

        Success(results)
      end

      private

      # Validates the input parameters
      #
      # @param [Hash] params The parameters to validate
      # @return [Dry::Monads::Success, Dry::Monads::Failure] The result of the validation
      def validate(params)
        result = ::Validators::Permissions::FindAndUpdateContract.new.call(params)

        if result.success?
          Success(result.to_h)
        else
          Failure(result.errors.to_h)
        end
      end

      # Processes the validated parameters to update permissions
      #
      # @param [Hash] validated_params The validated parameters
      # @return [Dry::Monads::Success] The result of the processing
      def process_updates(validated_params)
        Success(
          validated_params[:names].inject({}) do |result, name|
            result[name] = find_and_update_permission(name, validated_params)
            result
          end
        )
      end

      # Finds and updates a permission
      #
      # @param [String] name The name of the permission to update
      # @param [Hash] validated_params The validated parameters
      # @return [String] The result message of the update operation
      def find_and_update_permission(name, validated_params)
        permission = ::Permission.where(name: name).first
        return "Unable to find permission with given name: #{name}" if permission.blank?

        # This is to avoid updating the permission if the value is already set to the target value
        return "Permission with name: #{name} already has #{validated_params[:field_name]} set to #{validated_params[:field_value]}" if permission.send(validated_params[:field_name]) == validated_params[:field_value]

        permission.assign_attributes(
          validated_params[:field_name] => validated_params[:field_value]
        )
        permission.save!
        "Permission with name: #{name} updated successfully with #{validated_params[:field_name]} to #{validated_params[:field_value]}"
      rescue StandardError => e
        "Unable to find and update permission for given name: #{name} and params: #{validated_params} due to #{e.message}"
      end
    end
  end
end
