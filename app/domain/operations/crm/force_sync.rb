# frozen_string_literal: true

module Operations
  module Crm
    # This operation is responsible for initiating the force sync operation.
    class ForceSync
      include Dry::Monads[:do, :result]
      include EventSource::Command

      # Initiates the force sync operation.
      #
      # @param params [Hash] the parameters for the operation
      # @option params [Array<String>] :primary_hbx_ids an array of primary HBX IDs
      # @return [Dry::Monads::Result] the result of the operation
      def call(params)
        primary_person_hbx_ids  = yield validate(params)
        csv_file_name           = yield publish_families(primary_person_hbx_ids)
        message                 = yield generate_success_message(csv_file_name)

        Success(message)
      end

      private

      # Validates the input parameters.
      #
      # @param params [Hash] the parameters to validate
      # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure] the validation result
      def validate(params)
        if params[:primary_hbx_ids].is_a?(Array) && params[:primary_hbx_ids].present? && params[:primary_hbx_ids].all? { |id| id.is_a?(String) }
          Success(params[:primary_hbx_ids])
        else
          Failure("Invalid input for primary_hbx_ids: #{params[:primary_hbx_ids]}. Provide an array of HBX IDs.")
        end
      end

      # Publishes each family and logs o/p into a CSV file.
      #
      # @param primary_person_hbx_ids [Array<String>] an array of primary HBX IDs
      # @return [Dry::Monads::Result::Success, Dry::Monads::Result::Failure] the result of the publishing operation
      def publish_families(primary_person_hbx_ids)
        csv_file_name = "#{Rails.root}/crm_force_sync_#{DateTime.now.strftime('%Y_%m_%d_%H_%M_%S')}.csv"

        CSV.open(csv_file_name, 'w', force_quotes: true) do |csv|
          csv << ['Hbx ID', 'Result', 'Message']

          primary_person_hbx_ids.each do |hbx_id|
            result = ::Operations::Crm::Family::Publish.new.call(hbx_id: hbx_id)

            csv << [
              hbx_id,
              result.success? ? 'Success' : 'Failed',
              result.success? ? result.success : result.failure
            ]
          end
        end

        Success(csv_file_name)
      end

      def generate_success_message(csv_file_name)
        Success("Successfully published events for all families. Review the CSV file with results: #{csv_file_name}")
      end
    end
  end
end
